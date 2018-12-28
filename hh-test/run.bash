#/bin/bash

set -ex

# test code
#bin_path=/home/hong/code/a.out
#bin_cmd="/home/hong/code/a.out 100"
#load_base=0x400000

# evince
#bin_path=/usr/bin/evince
#bin_cmd="/usr/bin/evince /home/hong/Downloads/ucfi.pdf"
#load_base=0x555555554000

# grep
bin_path=/bin/grep
bin_cmd="/bin/grep -r foo /usr/include"
#bin_cmd="/bin/grep -r foo /usr/include"
load_base=0x555555554000

# clean up
echo -n "" > /tmp/123
echo -n "" > inst_dump
echo -n "" > trace_dump
rm -f perf.data-aux-idx*.bin 
rm -f perf.data-sideband-cpu*.pevent

# generate trace for /bin/ls
#
# -m:   set the buffer size
# -e:   the event to capture, here is intel_pt
#       tsc=0,mtc=0:disable particular packages
#       u: user space event only
# --per-thread:
# -a, --all-cpus
#       System-wide collection from all CPUs.
# --switch-events:
#       Record context switch events i.e. events of type PERF_RECORD_SWITCH or
#       PERF_RECORD_SWITCH_CPU_WIDE.
# -T:   timestamp
# --filter: 
#       filter start_address / size @path-to-file
# -- command options
#
echo "recoring" >> /tmp/123
#/usr/bin/time -p -a -o /tmp/123 perf record -m 512,10000 -e intel_pt/tsc=0,mtc=0/u  --switch-events -T --filter 'filter 0x3588 / 0x26dcd @/bin/grep ' -- /bin/grep -r foo /usr/include
#/usr/bin/time -p -a -o /tmp/123 perf record -m 512,10000 -e intel_pt/tsc=0,mtc=0/u  --switch-events -T --filter 'filter 0x19b30 / 0x3218d @/usr/bin/evince ' -- /usr/bin/evince ~/Downloads/ucfi.pdf
#/usr/bin/time -p -a -o /tmp/123 perf record -m 512,10000 -e intel_pt/tsc=0,mtc=0/u  --switch-events -T --filter 'filter 0x400000 / 0x1000000 @/bin/ls' -- /bin/ls -Rlh /usr/include
/usr/bin/time -p -a -o /tmp/123 perf record -m 512,10000 -e intel_pt/tsc=0,mtc=0/u  --switch-events -T --filter "filter * @$bin_path" -- $bin_cmd
echo "" >> /tmp/123

# extract the raw PT trace
echo "extract aux" >> /tmp/123
/usr/bin/time -p -a -o /tmp/123 ~/bin-debloating-code/processor-trace/script/perf-read-aux.bash
echo "" >> /tmp/123

# extract the sideband information
echo "extract sideband" >> /tmp/123
/usr/bin/time -p -a -o /tmp/123 ~/bin-debloating-code/processor-trace/script/perf-read-sideband.bash
echo "" >> /tmp/123

# get the trace dump
echo "ptdump" >> /tmp/123
for aux_data in $(ls perf.data-aux-idx*.bin); do
  echo $aux_data
  #/usr/bin/time -p -a -o /tmp/123 ptdump $(~/bin-debloating-code/processor-trace/script/perf-get-opts.bash) $aux_data &>> trace_dump
done
echo "" >> /tmp/123

# get the instruction dump
echo "ptxed" >> /tmp/123

for aux_data in $(ls perf.data-aux-idx*.bin); do
  echo $aux_data
  /usr/bin/time -p -a -o /tmp/123 ptxed --no-inst --decode-to-debloat --pt $aux_data --raw $bin_path:$load_base &>> inst_dump
done
echo "" >> /tmp/123

cat /tmp/123
