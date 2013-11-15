## Prerequisites

In order to compile and run the **smpplog** utility you need to have [Erlang](http://www.erlang.org/), [rebar](https://github.com/basho/rebar), and make installed.

## Compilation

<pre>
git clone https://github.com/PowerMeMobile/smpplog.git
cd smppload
make
</pre>

## Usage

<pre>
cd rel/smpplog/
./smpplog
smpplog &lt;smpplog-file&gt; &lt;csv-file&gt;

cat ../../test/smpp3.log
2013-11-15 00:35:20.002 > [info] SUBMIT_SM 2745613
2013-11-15 00:35:20.002 > [info] hex dump (176 bytes):
2013-11-15 00:35:20.002 > [info] 000000B0:00000004:00000000:0029E50D
2013-11-15 00:35:20.002 > [info] 00050141:54484545:52000101:39363539
2013-11-15 00:35:20.002 > [info] 39373637:37393300:00000100:30303030
2013-11-15 00:35:20.002 > [info] 30313030:30303030:30303052:00000008
2013-11-15 00:35:20.002 > [info] 006E062A:06300643:064A0631:000A000A
2013-11-15 00:35:20.002 > [info] 06270644:0644064A:06440629:000A000A
2013-11-15 00:35:20.002 > [info] 06230641:06310627:062D0020:06270644
2013-11-15 00:35:20.002 > [info] 06450646:064A0631:000A000A:06350627
2013-11-15 00:35:20.002 > [info] 06440629:00200645:06340628:06280020
2013-11-15 00:35:20.002 > [info] 06270644:062C0644:06270644:000A000A
2013-11-15 00:35:20.002 > [info] 00350035:00340034:00340035:00360031
2013-11-15 00:35:20.002 > [info] params:
2013-11-15 00:35:20.002 > [info] command_length=176,command_id=4,command_status=0,
2013-11-15 00:35:20.002 > [info] sequence_number=2745613,

./smpplog ../../test/smpp3.log csv.log

cat csv.log
datetime=2013-11-15 00:35:20.002;command_id=submit_sm;seq_num=2745613;src_addr="ATHEER";dst_addr="96599767793";encoding=8;body=تذكير\n\nالليلة\n\nأفراح المنير\n\nصالة مشبب الجلال\n\n55444561
</pre>
