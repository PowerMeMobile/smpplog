-module(smpplog).

-export([
	main/1
]).

-include_lib("oserl/include/oserl.hrl").

-record(pdu, {
	datetime :: string(),
	message  :: term()
}).

-spec main([string()]) -> no_return().
main([]) ->
	io:format("smpplog <smpplog-file> <csv-file>~n");
main([SmppLog, CsvLog]) ->
	process(SmppLog, CsvLog).

process(SmppLog, CsvLog) ->
	case file:open(SmppLog, [read]) of
		{ok, Fd} ->
			{ok, Pdus} = process_smpp_log(Fd),
			SubmitSMs = [Pdu || Pdu = #pdu{message = {?COMMAND_ID_SUBMIT_SM, _, _, _}} <- Pdus],
			io:format("~p~n", [SubmitSMs]),
			write_csv_log(CsvLog, SubmitSMs),
			file:close(Fd);
		{error, Reason} ->
			io:format("Open file ~p failed with: ~p~n", [SmppLog, Reason]),
			halt(1)
	end.

process_smpp_log(Fd) ->
	find_hex_dump(Fd, []).

write_csv_log(CsvLog, Pdus) ->
	case file:open(CsvLog, [write]) of
		{ok, Fd} ->
			BomUtf8 = unicode:encoding_to_bom(utf8),
			file:write(Fd, BomUtf8),
			[write_pdu(Fd, Pdu) || Pdu <- Pdus],
			file:close(Fd);
		{error, Reason} ->
			io:format("Open file ~p failed with: ~p~n", [CsvLog, Reason]),
			halt(1)
	end.

write_pdu(Fd, Pdu) ->
	Datetime = Pdu#pdu.datetime,
	{CmdId, _, SeqNum, Params} = Pdu#pdu.message,
	CmdName = ?COMMAND_NAME(CmdId),
	SrcAddr = proplists:get_value(source_addr, Params),
	DstAddr = proplists:get_value(destination_addr, Params),
	Encoding = proplists:get_value(data_coding, Params),
	Body = proplists:get_value(short_message, Params),
	{ok, Utf8} = iconverl:conv("utf-8//IGNORE", "ucs-2be", list_to_binary(Body)),
	Utf8Escaped = list_to_binary(escape(binary_to_list(Utf8))),
	io:fwrite(Fd, "datetime=~s;command_id=~p;seq_num=~p;src_addr=~p;dst_addr=~p;encoding=~p;body=~s~n",
		[Datetime, CmdName, SeqNum, SrcAddr, DstAddr, Encoding, Utf8Escaped]).

escape(Utf8) ->
	escape(Utf8, []).

escape([], Acc) ->
	lists:reverse(Acc);
escape([Char | Chars], Acc0) ->
	Acc1 =
		case Char of
			%% Escape sequences
			%% http://www.erlang.org/doc/reference_manual/data_types.html#id74018
			$\n -> [$n, $\\ | Acc0];
			$\a -> [$a, $\\ | Acc0];
			_   -> [Char | Acc0]
		end,
	escape(Chars, Acc1).

find_hex_dump(Fd, Pdus) ->
	case file:read_line(Fd) of
		{ok, Line} ->
			case string:str(Line, "hex dump") of
				0 ->
					find_hex_dump(Fd, Pdus);
				_ ->
					collect_hex_dump(Fd, [], Pdus)
			end;
		eof ->
			{ok, lists:reverse(Pdus)}
	end.

collect_hex_dump(Fd, HexDumpAcc, Pdus) ->
	case file:read_line(Fd) of
		{ok, Line} ->
			case string:str(Line, "params") of
				0 ->
					collect_hex_dump(Fd, [Line | HexDumpAcc], Pdus);
				_ ->
					{ok, Pdu} = process_hex_dump(lists:reverse(HexDumpAcc)),
					find_hex_dump(Fd, [Pdu | Pdus])
			end;
		eof ->
			{ok, lists:reverse(Pdus)}
	end.

process_hex_dump(Lines) ->
	Datetime = string:substr(hd(Lines), 1, 23),
	{ok, Message} = process_hex_dump(Lines, []),
	{ok, #pdu{datetime = Datetime, message = Message}}.

process_hex_dump([], HexDump) ->
	Binary = list_to_binary(hex_dump_to_list(HexDump)),
	smpp_operation:unpack(Binary);
process_hex_dump([Line | Lines], HexDump0) ->
	HexDump1 = [Char || Char <- string:substr(Line, 34), Char =/= $:, Char =/= $\n],
	process_hex_dump(Lines, HexDump0 ++ HexDump1).

hex_dump_to_list(HexStr) ->
	hex_dump_to_list(HexStr, []).

hex_dump_to_list([], Acc) ->
	lists:reverse(Acc);
hex_dump_to_list([F, S | Rest], Acc) ->
	{ok, [V], []} = io_lib:fread("~16u", [F, S]),
	hex_dump_to_list(Rest, [V | Acc]).
