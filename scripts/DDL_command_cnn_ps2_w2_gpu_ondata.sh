#!/bin/bash
# How to use: sudo bash DDL_command.sh
mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_sync_batch32_w1.json --graph_file=/benchmarks/cifar10_densenet40_k12_sync_batch32_w1.pbtxt 2> cifar10_densenet40_k12_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_sync_batch32_w2.json --graph_file=/benchmarks/cifar10_densenet40_k12_sync_batch32_w2.pbtxt 2> cifar10_densenet40_k12_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet40_k12_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_sync_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_sync_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_sync_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_sync_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_sync_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_sync_xla_w1.json --graph_file=/benchmarks/cifar10_densenet40_k12_sync_xla_w1.pbtxt 2> cifar10_densenet40_k12_sync_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_sync_xla_w2.json --graph_file=/benchmarks/cifar10_densenet40_k12_sync_xla_w2.pbtxt 2> cifar10_densenet40_k12_sync_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_sync_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_sync_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_sync_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet40_k12_sync_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_sync_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_sync_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_sync_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_sync_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_sync_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_async_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_async_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_async_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_async_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_async_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_async_dataFormat_w1.json --graph_file=/benchmarks/cifar10_densenet40_k12_async_dataFormat_w1.pbtxt 2> cifar10_densenet40_k12_async_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_async_dataFormat_w2.json --graph_file=/benchmarks/cifar10_densenet40_k12_async_dataFormat_w2.pbtxt 2> cifar10_densenet40_k12_async_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_async_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_async_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_async_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet40_k12_async_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_async_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_async_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_async_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_async_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_async_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet40_k12_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet40_k12_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_async_xla_w1.json --graph_file=/benchmarks/cifar10_densenet40_k12_async_xla_w1.pbtxt 2> cifar10_densenet40_k12_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet40_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet40_k12_async_xla_w2.json --graph_file=/benchmarks/cifar10_densenet40_k12_async_xla_w2.pbtxt 2> cifar10_densenet40_k12_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet40_k12_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet40_k12_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet40_k12_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet40_k12_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_batch128
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k12_async_batch128_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k12_async_batch128_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k12_async_batch128_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k12_async_batch128_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k12_async_batch128_w1.json --graph_file=/benchmarks/cifar10_densenet100_k12_async_batch128_w1.pbtxt 2> cifar10_densenet100_k12_async_batch128_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k12_async_batch128_w2.json --graph_file=/benchmarks/cifar10_densenet100_k12_async_batch128_w2.pbtxt 2> cifar10_densenet100_k12_async_batch128_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_batch128_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_batch128_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_batch128_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet100_k12_async_batch128_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_batch128_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_batch128_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_batch128_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_batch128/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_batch128/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k12_async_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k12_async_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k12_async_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k12_async_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k12_async_use_fp16_w1.json --graph_file=/benchmarks/cifar10_densenet100_k12_async_use_fp16_w1.pbtxt 2> cifar10_densenet100_k12_async_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k12_async_use_fp16_w2.json --graph_file=/benchmarks/cifar10_densenet100_k12_async_use_fp16_w2.pbtxt 2> cifar10_densenet100_k12_async_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet100_k12_async_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k12_async_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k12_async_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k12_async_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k12_async_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k12_async_winograd_w1.json --graph_file=/benchmarks/cifar10_densenet100_k12_async_winograd_w1.pbtxt 2> cifar10_densenet100_k12_async_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=densenet100_k12 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k12_async_winograd_w2.json --graph_file=/benchmarks/cifar10_densenet100_k12_async_winograd_w2.pbtxt 2> cifar10_densenet100_k12_async_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k12_async_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet100_k12_async_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k12_async_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k12_async_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_sync_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k24_sync_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k24_sync_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=densenet100_k24 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k24_sync_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=densenet100_k24 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k24_sync_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=densenet100_k24 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k24_sync_dataFormat_w1.json --graph_file=/benchmarks/cifar10_densenet100_k24_sync_dataFormat_w1.pbtxt 2> cifar10_densenet100_k24_sync_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=densenet100_k24 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k24_sync_dataFormat_w2.json --graph_file=/benchmarks/cifar10_densenet100_k24_sync_dataFormat_w2.pbtxt 2> cifar10_densenet100_k24_sync_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_sync_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_sync_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_sync_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet100_k24_sync_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_sync_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_sync_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_sync_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_sync_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_sync_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_async_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k24_async_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k24_async_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k24_async_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k24_async_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k24_async_use_fp16_w1.json --graph_file=/benchmarks/cifar10_densenet100_k24_async_use_fp16_w1.pbtxt 2> cifar10_densenet100_k24_async_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k24_async_use_fp16_w2.json --graph_file=/benchmarks/cifar10_densenet100_k24_async_use_fp16_w2.pbtxt 2> cifar10_densenet100_k24_async_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_async_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_async_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_async_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet100_k24_async_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_async_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_async_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_async_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_async_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_async_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k24_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_densenet100_k24_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k24_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_densenet100_k24_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k24_async_xla_w1.json --graph_file=/benchmarks/cifar10_densenet100_k24_async_xla_w1.pbtxt 2> cifar10_densenet100_k24_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=densenet100_k24 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_densenet100_k24_async_xla_w2.json --graph_file=/benchmarks/cifar10_densenet100_k24_async_xla_w2.pbtxt 2> cifar10_densenet100_k24_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_densenet100_k24_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_densenet100_k24_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_densenet100_k24_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_densenet100_k24_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_batch256
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_sync_batch256_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_sync_batch256_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_sync_batch256_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_sync_batch256_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_sync_batch256_w1.json --graph_file=/benchmarks/cifar10_resnet20_sync_batch256_w1.pbtxt 2> cifar10_resnet20_sync_batch256_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_sync_batch256_w2.json --graph_file=/benchmarks/cifar10_resnet20_sync_batch256_w2.pbtxt 2> cifar10_resnet20_sync_batch256_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_batch256_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_batch256_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_batch256_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet20_sync_batch256_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_batch256_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_batch256_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_batch256_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_batch256/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_batch256/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_sync_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_sync_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_sync_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_sync_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_sync_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_resnet20_sync_optRmsprop_w1.pbtxt 2> cifar10_resnet20_sync_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_sync_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_resnet20_sync_optRmsprop_w2.pbtxt 2> cifar10_resnet20_sync_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet20_sync_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_sync_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_sync_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_sync_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_sync_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_sync_dataFormat_w1.json --graph_file=/benchmarks/cifar10_resnet20_sync_dataFormat_w1.pbtxt 2> cifar10_resnet20_sync_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_sync_dataFormat_w2.json --graph_file=/benchmarks/cifar10_resnet20_sync_dataFormat_w2.pbtxt 2> cifar10_resnet20_sync_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_sync_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet20_sync_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_sync_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_sync_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_async_batch64
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_async_batch64_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_async_batch64_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_async_batch64_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet20 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_async_batch64_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_async_batch64_w1.json --graph_file=/benchmarks/cifar10_resnet20_async_batch64_w1.pbtxt 2> cifar10_resnet20_async_batch64_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet20 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_async_batch64_w2.json --graph_file=/benchmarks/cifar10_resnet20_async_batch64_w2.pbtxt 2> cifar10_resnet20_async_batch64_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_async_batch64_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_async_batch64_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_async_batch64_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet20_async_batch64_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_async_batch64_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_async_batch64_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_async_batch64_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_async_batch64/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_async_batch64/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_v2_sync_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_v2_sync_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet20_v2_sync_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_v2_sync_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet20_v2_sync_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_v2_sync_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_resnet20_v2_sync_optRmsprop_w1.pbtxt 2> cifar10_resnet20_v2_sync_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet20_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet20_v2_sync_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_resnet20_v2_sync_optRmsprop_w2.pbtxt 2> cifar10_resnet20_v2_sync_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_v2_sync_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_v2_sync_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet20_v2_sync_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet20_v2_sync_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_v2_sync_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_v2_sync_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet20_v2_sync_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_v2_sync_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet20_v2_sync_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_batch32_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_batch32_w1.pbtxt 2> cifar10_resnet32_v2_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_batch32_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_batch32_w2.pbtxt 2> cifar10_resnet32_v2_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_batch256
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_batch256_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_batch256_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_batch256_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_batch256_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_batch256_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_batch256_w1.pbtxt 2> cifar10_resnet32_v2_sync_batch256_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_batch256_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_batch256_w2.pbtxt 2> cifar10_resnet32_v2_sync_batch256_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_batch256_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_batch256_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_batch256_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_sync_batch256_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_batch256_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_batch256_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_batch256_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_batch256/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_batch256/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_dataFormat_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_dataFormat_w1.pbtxt 2> cifar10_resnet32_v2_sync_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_dataFormat_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_dataFormat_w2.pbtxt 2> cifar10_resnet32_v2_sync_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_sync_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_sync_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_sync_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_winograd_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_winograd_w1.pbtxt 2> cifar10_resnet32_v2_sync_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_sync_winograd_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_sync_winograd_w2.pbtxt 2> cifar10_resnet32_v2_sync_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_sync_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_sync_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_sync_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_sync_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_async_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_async_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_async_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_async_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_async_batch32_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_async_batch32_w1.pbtxt 2> cifar10_resnet32_v2_async_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_async_batch32_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_async_batch32_w2.pbtxt 2> cifar10_resnet32_v2_async_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_async_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_async_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_async_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_async_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_async_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_async_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_async_optRmsprop_w1.pbtxt 2> cifar10_resnet32_v2_async_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_async_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_async_optRmsprop_w2.pbtxt 2> cifar10_resnet32_v2_async_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_async_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet32_v2_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet32_v2_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_async_xla_w1.json --graph_file=/benchmarks/cifar10_resnet32_v2_async_xla_w1.pbtxt 2> cifar10_resnet32_v2_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet32_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet32_v2_async_xla_w2.json --graph_file=/benchmarks/cifar10_resnet32_v2_async_xla_w2.pbtxt 2> cifar10_resnet32_v2_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet32_v2_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet32_v2_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet32_v2_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet32_v2_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_sync_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_sync_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_sync_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_sync_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_sync_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_sync_winograd_w1.json --graph_file=/benchmarks/cifar10_resnet44_sync_winograd_w1.pbtxt 2> cifar10_resnet44_sync_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_sync_winograd_w2.json --graph_file=/benchmarks/cifar10_resnet44_sync_winograd_w2.pbtxt 2> cifar10_resnet44_sync_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_sync_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_sync_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_sync_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_sync_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_sync_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_sync_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_sync_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_sync_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_sync_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_async_optMomentum
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_async_optMomentum_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_async_optMomentum_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet44 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_async_optMomentum_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet44 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_async_optMomentum_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet44 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_async_optMomentum_w1.json --graph_file=/benchmarks/cifar10_resnet44_async_optMomentum_w1.pbtxt 2> cifar10_resnet44_async_optMomentum_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet44 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_async_optMomentum_w2.json --graph_file=/benchmarks/cifar10_resnet44_async_optMomentum_w2.pbtxt 2> cifar10_resnet44_async_optMomentum_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_async_optMomentum_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_async_optMomentum_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_async_optMomentum_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_async_optMomentum_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_async_optMomentum_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_async_optMomentum_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_async_optMomentum_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_async_optMomentum/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_async_optMomentum/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_async_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_async_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_async_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_async_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_async_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_async_dataFormat_w1.json --graph_file=/benchmarks/cifar10_resnet44_async_dataFormat_w1.pbtxt 2> cifar10_resnet44_async_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_async_dataFormat_w2.json --graph_file=/benchmarks/cifar10_resnet44_async_dataFormat_w2.pbtxt 2> cifar10_resnet44_async_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_async_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_async_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_async_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_async_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_async_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_async_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_async_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_async_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_async_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_sync_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_sync_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_sync_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_sync_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_sync_use_fp16_w1.json --graph_file=/benchmarks/cifar10_resnet44_v2_sync_use_fp16_w1.pbtxt 2> cifar10_resnet44_v2_sync_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_sync_use_fp16_w2.json --graph_file=/benchmarks/cifar10_resnet44_v2_sync_use_fp16_w2.pbtxt 2> cifar10_resnet44_v2_sync_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_v2_sync_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_sync_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_sync_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_sync_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_sync_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_sync_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_resnet44_v2_sync_optRmsprop_w1.pbtxt 2> cifar10_resnet44_v2_sync_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_sync_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_resnet44_v2_sync_optRmsprop_w2.pbtxt 2> cifar10_resnet44_v2_sync_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_v2_sync_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_sync_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_sync_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_sync_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_sync_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_sync_winograd_w1.json --graph_file=/benchmarks/cifar10_resnet44_v2_sync_winograd_w1.pbtxt 2> cifar10_resnet44_v2_sync_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_sync_winograd_w2.json --graph_file=/benchmarks/cifar10_resnet44_v2_sync_winograd_w2.pbtxt 2> cifar10_resnet44_v2_sync_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_sync_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_v2_sync_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_sync_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_sync_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_async_batch256
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_async_batch256_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_async_batch256_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_async_batch256_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_async_batch256_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_async_batch256_w1.json --graph_file=/benchmarks/cifar10_resnet44_v2_async_batch256_w1.pbtxt 2> cifar10_resnet44_v2_async_batch256_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_async_batch256_w2.json --graph_file=/benchmarks/cifar10_resnet44_v2_async_batch256_w2.pbtxt 2> cifar10_resnet44_v2_async_batch256_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_async_batch256_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_async_batch256_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_async_batch256_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_v2_async_batch256_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_async_batch256_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_async_batch256_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_async_batch256_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_async_batch256/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_async_batch256/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_async_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_async_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet44_v2_async_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_async_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet44_v2_async_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_async_dataFormat_w1.json --graph_file=/benchmarks/cifar10_resnet44_v2_async_dataFormat_w1.pbtxt 2> cifar10_resnet44_v2_async_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet44_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet44_v2_async_dataFormat_w2.json --graph_file=/benchmarks/cifar10_resnet44_v2_async_dataFormat_w2.pbtxt 2> cifar10_resnet44_v2_async_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_async_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_async_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet44_v2_async_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet44_v2_async_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_async_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_async_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet44_v2_async_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_async_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet44_v2_async_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_sync_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_sync_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_sync_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet56 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_sync_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet56 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_sync_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet56 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_sync_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_resnet56_sync_optRmsprop_w1.pbtxt 2> cifar10_resnet56_sync_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=resnet56 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_sync_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_resnet56_sync_optRmsprop_w2.pbtxt 2> cifar10_resnet56_sync_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_sync_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_sync_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_sync_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet56_sync_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_sync_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_sync_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_sync_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_sync_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_sync_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_async_batch128
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_async_batch128_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_async_batch128_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet56 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_async_batch128_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet56 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_async_batch128_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet56 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_async_batch128_w1.json --graph_file=/benchmarks/cifar10_resnet56_async_batch128_w1.pbtxt 2> cifar10_resnet56_async_batch128_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet56 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_async_batch128_w2.json --graph_file=/benchmarks/cifar10_resnet56_async_batch128_w2.pbtxt 2> cifar10_resnet56_async_batch128_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_async_batch128_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_async_batch128_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_async_batch128_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet56_async_batch128_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_async_batch128_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_async_batch128_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_async_batch128_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_async_batch128/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_async_batch128/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_async_batch512
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_async_batch512_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_async_batch512_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet56 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_async_batch512_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet56 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_async_batch512_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet56 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_async_batch512_w1.json --graph_file=/benchmarks/cifar10_resnet56_async_batch512_w1.pbtxt 2> cifar10_resnet56_async_batch512_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet56 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_async_batch512_w2.json --graph_file=/benchmarks/cifar10_resnet56_async_batch512_w2.pbtxt 2> cifar10_resnet56_async_batch512_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_async_batch512_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_async_batch512_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_async_batch512_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet56_async_batch512_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_async_batch512_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_async_batch512_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_async_batch512_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_async_batch512/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_async_batch512/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_v2_sync_batch256
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_v2_sync_batch256_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_v2_sync_batch256_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_v2_sync_batch256_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_v2_sync_batch256_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_v2_sync_batch256_w1.json --graph_file=/benchmarks/cifar10_resnet56_v2_sync_batch256_w1.pbtxt 2> cifar10_resnet56_v2_sync_batch256_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_v2_sync_batch256_w2.json --graph_file=/benchmarks/cifar10_resnet56_v2_sync_batch256_w2.pbtxt 2> cifar10_resnet56_v2_sync_batch256_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_v2_sync_batch256_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_v2_sync_batch256_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_v2_sync_batch256_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet56_v2_sync_batch256_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_v2_sync_batch256_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_v2_sync_batch256_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_v2_sync_batch256_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_v2_sync_batch256/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_v2_sync_batch256/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_v2_sync_batch512
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_v2_sync_batch512_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet56_v2_sync_batch512_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_v2_sync_batch512_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet56_v2_sync_batch512_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_v2_sync_batch512_w1.json --graph_file=/benchmarks/cifar10_resnet56_v2_sync_batch512_w1.pbtxt 2> cifar10_resnet56_v2_sync_batch512_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=resnet56_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet56_v2_sync_batch512_w2.json --graph_file=/benchmarks/cifar10_resnet56_v2_sync_batch512_w2.pbtxt 2> cifar10_resnet56_v2_sync_batch512_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_v2_sync_batch512_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_v2_sync_batch512_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet56_v2_sync_batch512_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet56_v2_sync_batch512_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_v2_sync_batch512_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_v2_sync_batch512_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet56_v2_sync_batch512_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_v2_sync_batch512/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet56_v2_sync_batch512/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_sync_batch64
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_sync_batch64_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_sync_batch64_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=true --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_sync_batch64_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=true --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_sync_batch64_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=true --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_sync_batch64_w1.json --graph_file=/benchmarks/cifar10_resnet110_sync_batch64_w1.pbtxt 2> cifar10_resnet110_sync_batch64_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=true --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_sync_batch64_w2.json --graph_file=/benchmarks/cifar10_resnet110_sync_batch64_w2.pbtxt 2> cifar10_resnet110_sync_batch64_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_sync_batch64_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_sync_batch64_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_sync_batch64_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_sync_batch64_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_sync_batch64_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_sync_batch64_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_sync_batch64_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_sync_batch64/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_sync_batch64/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch32_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_batch32_w1.pbtxt 2> cifar10_resnet110_async_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch32_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_batch32_w2.pbtxt 2> cifar10_resnet110_async_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch64
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch64_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch64_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch64_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch64_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch64_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_batch64_w1.pbtxt 2> cifar10_resnet110_async_batch64_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch64_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_batch64_w2.pbtxt 2> cifar10_resnet110_async_batch64_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch64_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch64_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch64_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_batch64_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch64_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch64_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch64_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch64/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch64/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch128
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch128_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch128_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch128_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch128_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch128_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_batch128_w1.pbtxt 2> cifar10_resnet110_async_batch128_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch128_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_batch128_w2.pbtxt 2> cifar10_resnet110_async_batch128_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch128_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch128_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch128_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_batch128_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch128_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch128_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch128_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch128/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch128/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch512
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch512_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_batch512_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch512_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_batch512_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch512_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_batch512_w1.pbtxt 2> cifar10_resnet110_async_batch512_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_batch512_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_batch512_w2.pbtxt 2> cifar10_resnet110_async_batch512_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch512_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch512_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_batch512_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_batch512_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch512_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch512_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_batch512_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch512/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_batch512/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_optRmsprop_w1.pbtxt 2> cifar10_resnet110_async_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_optRmsprop_w2.pbtxt 2> cifar10_resnet110_async_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_winograd_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_winograd_w1.pbtxt 2> cifar10_resnet110_async_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_winograd_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_winograd_w2.pbtxt 2> cifar10_resnet110_async_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_xla_w1.json --graph_file=/benchmarks/cifar10_resnet110_async_xla_w1.pbtxt 2> cifar10_resnet110_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_async_xla_w2.json --graph_file=/benchmarks/cifar10_resnet110_async_xla_w2.pbtxt 2> cifar10_resnet110_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_sync_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_v2_sync_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_v2_sync_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet110_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_v2_sync_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet110_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_v2_sync_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet110_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_v2_sync_dataFormat_w1.json --graph_file=/benchmarks/cifar10_resnet110_v2_sync_dataFormat_w1.pbtxt 2> cifar10_resnet110_v2_sync_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet110_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_v2_sync_dataFormat_w2.json --graph_file=/benchmarks/cifar10_resnet110_v2_sync_dataFormat_w2.pbtxt 2> cifar10_resnet110_v2_sync_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_sync_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_sync_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_sync_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_v2_sync_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_sync_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_sync_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_sync_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_sync_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_sync_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_async_optMomentum
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_v2_async_optMomentum_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_v2_async_optMomentum_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_v2_async_optMomentum_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_v2_async_optMomentum_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_v2_async_optMomentum_w1.json --graph_file=/benchmarks/cifar10_resnet110_v2_async_optMomentum_w1.pbtxt 2> cifar10_resnet110_v2_async_optMomentum_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_v2_async_optMomentum_w2.json --graph_file=/benchmarks/cifar10_resnet110_v2_async_optMomentum_w2.pbtxt 2> cifar10_resnet110_v2_async_optMomentum_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_async_optMomentum_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_async_optMomentum_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_async_optMomentum_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_v2_async_optMomentum_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_async_optMomentum_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_async_optMomentum_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_async_optMomentum_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_async_optMomentum/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_async_optMomentum/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_v2_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_resnet110_v2_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_v2_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_resnet110_v2_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_v2_async_xla_w1.json --graph_file=/benchmarks/cifar10_resnet110_v2_async_xla_w1.pbtxt 2> cifar10_resnet110_v2_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=resnet110_v2 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_resnet110_v2_async_xla_w2.json --graph_file=/benchmarks/cifar10_resnet110_v2_async_xla_w2.pbtxt 2> cifar10_resnet110_v2_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_resnet110_v2_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_resnet110_v2_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_resnet110_v2_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_resnet110_v2_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_sync_batch256
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_alexnet_sync_batch256_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_alexnet_sync_batch256_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=alexnet --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_alexnet_sync_batch256_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=alexnet --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_alexnet_sync_batch256_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=alexnet --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_alexnet_sync_batch256_w1.json --graph_file=/benchmarks/cifar10_alexnet_sync_batch256_w1.pbtxt 2> cifar10_alexnet_sync_batch256_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=alexnet --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_alexnet_sync_batch256_w2.json --graph_file=/benchmarks/cifar10_alexnet_sync_batch256_w2.pbtxt 2> cifar10_alexnet_sync_batch256_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_sync_batch256_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_sync_batch256_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_sync_batch256_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_alexnet_sync_batch256_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_sync_batch256_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_sync_batch256_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_sync_batch256_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_sync_batch256/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_sync_batch256/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_async_batch128
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_alexnet_async_batch128_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_alexnet_async_batch128_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=alexnet --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_alexnet_async_batch128_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=alexnet --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_alexnet_async_batch128_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=alexnet --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_alexnet_async_batch128_w1.json --graph_file=/benchmarks/cifar10_alexnet_async_batch128_w1.pbtxt 2> cifar10_alexnet_async_batch128_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=false --model=alexnet --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_alexnet_async_batch128_w2.json --graph_file=/benchmarks/cifar10_alexnet_async_batch128_w2.pbtxt 2> cifar10_alexnet_async_batch128_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_async_batch128_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_async_batch128_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_async_batch128_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_alexnet_async_batch128_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_async_batch128_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_async_batch128_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_async_batch128_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_async_batch128/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_async_batch128/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_async_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_alexnet_async_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_alexnet_async_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=alexnet --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_alexnet_async_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=alexnet --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_alexnet_async_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=alexnet --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_alexnet_async_optRmsprop_w1.json --graph_file=/benchmarks/cifar10_alexnet_async_optRmsprop_w1.pbtxt 2> cifar10_alexnet_async_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=alexnet --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_alexnet_async_optRmsprop_w2.json --graph_file=/benchmarks/cifar10_alexnet_async_optRmsprop_w2.pbtxt 2> cifar10_alexnet_async_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_async_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_async_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_alexnet_async_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_alexnet_async_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_async_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_async_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_alexnet_async_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_async_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_alexnet_async_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_vgg16_sync_batch256
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_vgg16_sync_batch256_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/cifar10_vgg16_sync_batch256_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=vgg16 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_vgg16_sync_batch256_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=vgg16 --data_name=cifar10 --num_batches=11 --display_every=1  2> cifar10_vgg16_sync_batch256_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=vgg16 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_vgg16_sync_batch256_w1.json --graph_file=/benchmarks/cifar10_vgg16_sync_batch256_w1.pbtxt 2> cifar10_vgg16_sync_batch256_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=256 --cross_replica_sync=true --model=vgg16 --data_name=cifar10  --num_batches=11 --display_every=1 --trace_file=/benchmarks/cifar10_vgg16_sync_batch256_w2.json --graph_file=/benchmarks/cifar10_vgg16_sync_batch256_w2.pbtxt 2> cifar10_vgg16_sync_batch256_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_vgg16_sync_batch256_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_vgg16_sync_batch256_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/cifar10_vgg16_sync_batch256_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv cifar10_vgg16_sync_batch256_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_vgg16_sync_batch256_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_vgg16_sync_batch256_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv cifar10_vgg16_sync_batch256_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_vgg16_sync_batch256/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/cifar10_vgg16_sync_batch256/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_sync_batch32_w1.json --graph_file=/benchmarks/imagenet_overfeat_sync_batch32_w1.pbtxt 2> imagenet_overfeat_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_sync_batch32_w2.json --graph_file=/benchmarks/imagenet_overfeat_sync_batch32_w2.pbtxt 2> imagenet_overfeat_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_overfeat_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_sync_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_sync_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_sync_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_sync_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_sync_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_sync_use_fp16_w1.json --graph_file=/benchmarks/imagenet_overfeat_sync_use_fp16_w1.pbtxt 2> imagenet_overfeat_sync_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_sync_use_fp16_w2.json --graph_file=/benchmarks/imagenet_overfeat_sync_use_fp16_w2.pbtxt 2> imagenet_overfeat_sync_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_sync_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_sync_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_sync_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_overfeat_sync_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_sync_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_sync_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_sync_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_sync_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_sync_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_async_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_async_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_async_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_async_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_async_batch32_w1.json --graph_file=/benchmarks/imagenet_overfeat_async_batch32_w1.pbtxt 2> imagenet_overfeat_async_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=false --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_async_batch32_w2.json --graph_file=/benchmarks/imagenet_overfeat_async_batch32_w2.pbtxt 2> imagenet_overfeat_async_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_overfeat_async_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_async_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_async_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_async_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_async_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_async_dataFormat_w1.json --graph_file=/benchmarks/imagenet_overfeat_async_dataFormat_w1.pbtxt 2> imagenet_overfeat_async_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_async_dataFormat_w2.json --graph_file=/benchmarks/imagenet_overfeat_async_dataFormat_w2.pbtxt 2> imagenet_overfeat_async_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_overfeat_async_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_overfeat_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=overfeat --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_overfeat_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_async_xla_w1.json --graph_file=/benchmarks/imagenet_overfeat_async_xla_w1.pbtxt 2> imagenet_overfeat_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=overfeat --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_overfeat_async_xla_w2.json --graph_file=/benchmarks/imagenet_overfeat_async_xla_w2.pbtxt 2> imagenet_overfeat_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_overfeat_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_overfeat_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_overfeat_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_overfeat_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception3_async_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_inception3_async_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_inception3_async_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=inception3 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_inception3_async_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=inception3 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_inception3_async_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=inception3 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_inception3_async_optRmsprop_w1.json --graph_file=/benchmarks/imagenet_inception3_async_optRmsprop_w1.pbtxt 2> imagenet_inception3_async_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=inception3 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_inception3_async_optRmsprop_w2.json --graph_file=/benchmarks/imagenet_inception3_async_optRmsprop_w2.pbtxt 2> imagenet_inception3_async_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception3_async_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception3_async_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception3_async_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_inception3_async_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception3_async_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception3_async_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception3_async_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception3_async_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception3_async_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception4_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_inception4_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_inception4_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=inception4 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_inception4_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=inception4 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_inception4_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=inception4 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_inception4_sync_batch32_w1.json --graph_file=/benchmarks/imagenet_inception4_sync_batch32_w1.pbtxt 2> imagenet_inception4_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=inception4 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_inception4_sync_batch32_w2.json --graph_file=/benchmarks/imagenet_inception4_sync_batch32_w2.pbtxt 2> imagenet_inception4_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception4_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception4_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception4_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_inception4_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception4_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception4_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception4_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception4_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception4_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception4_async_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_inception4_async_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_inception4_async_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=inception4 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_inception4_async_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=inception4 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_inception4_async_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=inception4 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_inception4_async_use_fp16_w1.json --graph_file=/benchmarks/imagenet_inception4_async_use_fp16_w1.pbtxt 2> imagenet_inception4_async_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=inception4 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_inception4_async_use_fp16_w2.json --graph_file=/benchmarks/imagenet_inception4_async_use_fp16_w2.pbtxt 2> imagenet_inception4_async_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception4_async_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception4_async_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_inception4_async_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_inception4_async_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception4_async_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception4_async_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_inception4_async_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception4_async_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_inception4_async_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet50_sync_batch128
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet50_sync_batch128_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet50_sync_batch128_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=true --model=resnet50 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet50_sync_batch128_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=true --model=resnet50 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet50_sync_batch128_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=true --model=resnet50 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet50_sync_batch128_w1.json --graph_file=/benchmarks/imagenet_resnet50_sync_batch128_w1.pbtxt 2> imagenet_resnet50_sync_batch128_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=128 --cross_replica_sync=true --model=resnet50 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet50_sync_batch128_w2.json --graph_file=/benchmarks/imagenet_resnet50_sync_batch128_w2.pbtxt 2> imagenet_resnet50_sync_batch128_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet50_sync_batch128_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet50_sync_batch128_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet50_sync_batch128_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet50_sync_batch128_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet50_sync_batch128_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet50_sync_batch128_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet50_sync_batch128_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet50_sync_batch128/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet50_sync_batch128/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet50_v2_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet50_v2_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet50_v2_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet50_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet50_v2_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet50_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet50_v2_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet50_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet50_v2_sync_batch32_w1.json --graph_file=/benchmarks/imagenet_resnet50_v2_sync_batch32_w1.pbtxt 2> imagenet_resnet50_v2_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet50_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet50_v2_sync_batch32_w2.json --graph_file=/benchmarks/imagenet_resnet50_v2_sync_batch32_w2.pbtxt 2> imagenet_resnet50_v2_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet50_v2_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet50_v2_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet50_v2_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet50_v2_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet50_v2_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet50_v2_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet50_v2_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet50_v2_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet50_v2_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_sync_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_sync_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_sync_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_sync_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_sync_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_sync_use_fp16_w1.json --graph_file=/benchmarks/imagenet_resnet101_sync_use_fp16_w1.pbtxt 2> imagenet_resnet101_sync_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_sync_use_fp16_w2.json --graph_file=/benchmarks/imagenet_resnet101_sync_use_fp16_w2.pbtxt 2> imagenet_resnet101_sync_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_sync_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_sync_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_sync_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_sync_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_sync_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_sync_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_sync_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_sync_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_sync_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_sync_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_sync_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_sync_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_sync_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_sync_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_sync_dataFormat_w1.json --graph_file=/benchmarks/imagenet_resnet101_sync_dataFormat_w1.pbtxt 2> imagenet_resnet101_sync_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_sync_dataFormat_w2.json --graph_file=/benchmarks/imagenet_resnet101_sync_dataFormat_w2.pbtxt 2> imagenet_resnet101_sync_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_sync_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_sync_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_sync_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_sync_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_sync_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_sync_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_sync_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_sync_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_sync_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_batch64
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_async_batch64_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_async_batch64_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_async_batch64_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_async_batch64_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_async_batch64_w1.json --graph_file=/benchmarks/imagenet_resnet101_async_batch64_w1.pbtxt 2> imagenet_resnet101_async_batch64_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --cross_replica_sync=false --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_async_batch64_w2.json --graph_file=/benchmarks/imagenet_resnet101_async_batch64_w2.pbtxt 2> imagenet_resnet101_async_batch64_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_batch64_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_batch64_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_batch64_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_async_batch64_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_batch64_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_batch64_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_batch64_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_batch64/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_batch64/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_optMomentum
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_async_optMomentum_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_async_optMomentum_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_async_optMomentum_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_async_optMomentum_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_async_optMomentum_w1.json --graph_file=/benchmarks/imagenet_resnet101_async_optMomentum_w1.pbtxt 2> imagenet_resnet101_async_optMomentum_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_async_optMomentum_w2.json --graph_file=/benchmarks/imagenet_resnet101_async_optMomentum_w2.pbtxt 2> imagenet_resnet101_async_optMomentum_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_optMomentum_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_optMomentum_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_optMomentum_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_async_optMomentum_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_optMomentum_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_optMomentum_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_optMomentum_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_optMomentum/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_optMomentum/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_async_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_async_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_async_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet101 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_async_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_async_dataFormat_w1.json --graph_file=/benchmarks/imagenet_resnet101_async_dataFormat_w1.pbtxt 2> imagenet_resnet101_async_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=false --model=resnet101 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_async_dataFormat_w2.json --graph_file=/benchmarks/imagenet_resnet101_async_dataFormat_w2.pbtxt 2> imagenet_resnet101_async_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_async_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_async_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_async_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_async_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_v2_sync_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_v2_sync_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_v2_sync_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_v2_sync_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_v2_sync_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_v2_sync_use_fp16_w1.json --graph_file=/benchmarks/imagenet_resnet101_v2_sync_use_fp16_w1.pbtxt 2> imagenet_resnet101_v2_sync_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=resnet101_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_v2_sync_use_fp16_w2.json --graph_file=/benchmarks/imagenet_resnet101_v2_sync_use_fp16_w2.pbtxt 2> imagenet_resnet101_v2_sync_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_v2_sync_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_v2_sync_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_v2_sync_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_v2_sync_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_v2_sync_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_v2_sync_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_v2_sync_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_v2_sync_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_v2_sync_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_v2_async_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_v2_async_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet101_v2_async_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet101_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_v2_async_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet101_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet101_v2_async_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet101_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_v2_async_optRmsprop_w1.json --graph_file=/benchmarks/imagenet_resnet101_v2_async_optRmsprop_w1.pbtxt 2> imagenet_resnet101_v2_async_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=resnet101_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet101_v2_async_optRmsprop_w2.json --graph_file=/benchmarks/imagenet_resnet101_v2_async_optRmsprop_w2.pbtxt 2> imagenet_resnet101_v2_async_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_v2_async_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_v2_async_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet101_v2_async_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet101_v2_async_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_v2_async_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_v2_async_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet101_v2_async_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_v2_async_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet101_v2_async_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_sync_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_sync_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_sync_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet152 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_sync_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet152 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_sync_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet152 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_sync_winograd_w1.json --graph_file=/benchmarks/imagenet_resnet152_sync_winograd_w1.pbtxt 2> imagenet_resnet152_sync_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=resnet152 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_sync_winograd_w2.json --graph_file=/benchmarks/imagenet_resnet152_sync_winograd_w2.pbtxt 2> imagenet_resnet152_sync_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_sync_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_sync_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_sync_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet152_sync_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_sync_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_sync_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_sync_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_sync_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_sync_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_async_optMomentum
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_async_optMomentum_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_async_optMomentum_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_async_optMomentum_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_async_optMomentum_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_async_optMomentum_w1.json --graph_file=/benchmarks/imagenet_resnet152_async_optMomentum_w1.pbtxt 2> imagenet_resnet152_async_optMomentum_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_async_optMomentum_w2.json --graph_file=/benchmarks/imagenet_resnet152_async_optMomentum_w2.pbtxt 2> imagenet_resnet152_async_optMomentum_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_async_optMomentum_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_async_optMomentum_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_async_optMomentum_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet152_async_optMomentum_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_async_optMomentum_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_async_optMomentum_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_async_optMomentum_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_async_optMomentum/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_async_optMomentum/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_v2_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_v2_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_v2_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_v2_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_v2_sync_batch32_w1.json --graph_file=/benchmarks/imagenet_resnet152_v2_sync_batch32_w1.pbtxt 2> imagenet_resnet152_v2_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_v2_sync_batch32_w2.json --graph_file=/benchmarks/imagenet_resnet152_v2_sync_batch32_w2.pbtxt 2> imagenet_resnet152_v2_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet152_v2_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_sync_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_v2_sync_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_v2_sync_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_v2_sync_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_v2_sync_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_v2_sync_xla_w1.json --graph_file=/benchmarks/imagenet_resnet152_v2_sync_xla_w1.pbtxt 2> imagenet_resnet152_v2_sync_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=resnet152_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_v2_sync_xla_w2.json --graph_file=/benchmarks/imagenet_resnet152_v2_sync_xla_w2.pbtxt 2> imagenet_resnet152_v2_sync_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_sync_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_sync_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_sync_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet152_v2_sync_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_sync_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_sync_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_sync_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_sync_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_sync_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_async_optMomentum
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_v2_async_optMomentum_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_resnet152_v2_async_optMomentum_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_v2_async_optMomentum_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152_v2 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_resnet152_v2_async_optMomentum_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_v2_async_optMomentum_w1.json --graph_file=/benchmarks/imagenet_resnet152_v2_async_optMomentum_w1.pbtxt 2> imagenet_resnet152_v2_async_optMomentum_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=resnet152_v2 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_resnet152_v2_async_optMomentum_w2.json --graph_file=/benchmarks/imagenet_resnet152_v2_async_optMomentum_w2.pbtxt 2> imagenet_resnet152_v2_async_optMomentum_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_async_optMomentum_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_async_optMomentum_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_resnet152_v2_async_optMomentum_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_resnet152_v2_async_optMomentum_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_async_optMomentum_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_async_optMomentum_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_resnet152_v2_async_optMomentum_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_async_optMomentum/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_resnet152_v2_async_optMomentum/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_alexnet_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_alexnet_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_alexnet_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=alexnet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_alexnet_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=alexnet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_alexnet_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=alexnet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_alexnet_sync_batch32_w1.json --graph_file=/benchmarks/imagenet_alexnet_sync_batch32_w1.pbtxt 2> imagenet_alexnet_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=alexnet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_alexnet_sync_batch32_w2.json --graph_file=/benchmarks/imagenet_alexnet_sync_batch32_w2.pbtxt 2> imagenet_alexnet_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_alexnet_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_alexnet_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_alexnet_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_alexnet_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_alexnet_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_alexnet_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_alexnet_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_alexnet_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_alexnet_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_alexnet_sync_batch512
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_alexnet_sync_batch512_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_alexnet_sync_batch512_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=alexnet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_alexnet_sync_batch512_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=alexnet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_alexnet_sync_batch512_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=alexnet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_alexnet_sync_batch512_w1.json --graph_file=/benchmarks/imagenet_alexnet_sync_batch512_w1.pbtxt 2> imagenet_alexnet_sync_batch512_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=512 --cross_replica_sync=true --model=alexnet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_alexnet_sync_batch512_w2.json --graph_file=/benchmarks/imagenet_alexnet_sync_batch512_w2.pbtxt 2> imagenet_alexnet_sync_batch512_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_alexnet_sync_batch512_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_alexnet_sync_batch512_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_alexnet_sync_batch512_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_alexnet_sync_batch512_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_alexnet_sync_batch512_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_alexnet_sync_batch512_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_alexnet_sync_batch512_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_alexnet_sync_batch512/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_alexnet_sync_batch512/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_sync_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_sync_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_sync_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_sync_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_sync_optRmsprop_w1.json --graph_file=/benchmarks/imagenet_googlenet_sync_optRmsprop_w1.pbtxt 2> imagenet_googlenet_sync_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_sync_optRmsprop_w2.json --graph_file=/benchmarks/imagenet_googlenet_sync_optRmsprop_w2.pbtxt 2> imagenet_googlenet_sync_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_googlenet_sync_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_dataFormat
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_sync_dataFormat_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_sync_dataFormat_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_sync_dataFormat_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_sync_dataFormat_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_sync_dataFormat_w1.json --graph_file=/benchmarks/imagenet_googlenet_sync_dataFormat_w1.pbtxt 2> imagenet_googlenet_sync_dataFormat_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --data_format=NCHW --cross_replica_sync=true --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_sync_dataFormat_w2.json --graph_file=/benchmarks/imagenet_googlenet_sync_dataFormat_w2.pbtxt 2> imagenet_googlenet_sync_dataFormat_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_dataFormat_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_dataFormat_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_dataFormat_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_googlenet_sync_dataFormat_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_dataFormat_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_dataFormat_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_dataFormat_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_dataFormat/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_dataFormat/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_winograd
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_sync_winograd_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_sync_winograd_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_sync_winograd_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_sync_winograd_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_sync_winograd_w1.json --graph_file=/benchmarks/imagenet_googlenet_sync_winograd_w1.pbtxt 2> imagenet_googlenet_sync_winograd_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --winograd_nonfused=false --cross_replica_sync=true --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_sync_winograd_w2.json --graph_file=/benchmarks/imagenet_googlenet_sync_winograd_w2.pbtxt 2> imagenet_googlenet_sync_winograd_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_winograd_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_winograd_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_sync_winograd_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_googlenet_sync_winograd_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_winograd_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_winograd_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_sync_winograd_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_winograd/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_sync_winograd/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_async_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_async_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_async_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_async_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_async_use_fp16_w1.json --graph_file=/benchmarks/imagenet_googlenet_async_use_fp16_w1.pbtxt 2> imagenet_googlenet_async_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=false --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_async_use_fp16_w2.json --graph_file=/benchmarks/imagenet_googlenet_async_use_fp16_w2.pbtxt 2> imagenet_googlenet_async_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_googlenet_async_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_use_fp16/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_optMomentum
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_async_optMomentum_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_async_optMomentum_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_async_optMomentum_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_async_optMomentum_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_async_optMomentum_w1.json --graph_file=/benchmarks/imagenet_googlenet_async_optMomentum_w1.pbtxt 2> imagenet_googlenet_async_optMomentum_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=momentum --cross_replica_sync=false --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_async_optMomentum_w2.json --graph_file=/benchmarks/imagenet_googlenet_async_optMomentum_w2.pbtxt 2> imagenet_googlenet_async_optMomentum_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_optMomentum_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_optMomentum_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_optMomentum_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_googlenet_async_optMomentum_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_optMomentum_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_optMomentum_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_optMomentum_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_optMomentum/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_optMomentum/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_async_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_googlenet_async_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_async_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=googlenet --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_googlenet_async_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_async_optRmsprop_w1.json --graph_file=/benchmarks/imagenet_googlenet_async_optRmsprop_w1.pbtxt 2> imagenet_googlenet_async_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=false --model=googlenet --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_googlenet_async_optRmsprop_w2.json --graph_file=/benchmarks/imagenet_googlenet_async_optRmsprop_w2.pbtxt 2> imagenet_googlenet_async_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_googlenet_async_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_googlenet_async_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_googlenet_async_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_googlenet_async_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg11_sync_optRmsprop
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg11_sync_optRmsprop_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg11_sync_optRmsprop_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=vgg11 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg11_sync_optRmsprop_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=vgg11 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg11_sync_optRmsprop_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=vgg11 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg11_sync_optRmsprop_w1.json --graph_file=/benchmarks/imagenet_vgg11_sync_optRmsprop_w1.pbtxt 2> imagenet_vgg11_sync_optRmsprop_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --optimizer=rmsprop --cross_replica_sync=true --model=vgg11 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg11_sync_optRmsprop_w2.json --graph_file=/benchmarks/imagenet_vgg11_sync_optRmsprop_w2.pbtxt 2> imagenet_vgg11_sync_optRmsprop_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg11_sync_optRmsprop_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg11_sync_optRmsprop_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg11_sync_optRmsprop_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_vgg11_sync_optRmsprop_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg11_sync_optRmsprop_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg11_sync_optRmsprop_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg11_sync_optRmsprop_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg11_sync_optRmsprop/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg11_sync_optRmsprop/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_sync_batch32
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg16_sync_batch32_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg16_sync_batch32_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=vgg16 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg16_sync_batch32_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=vgg16 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg16_sync_batch32_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=vgg16 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg16_sync_batch32_w1.json --graph_file=/benchmarks/imagenet_vgg16_sync_batch32_w1.pbtxt 2> imagenet_vgg16_sync_batch32_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=32 --cross_replica_sync=true --model=vgg16 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg16_sync_batch32_w2.json --graph_file=/benchmarks/imagenet_vgg16_sync_batch32_w2.pbtxt 2> imagenet_vgg16_sync_batch32_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_sync_batch32_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_sync_batch32_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_sync_batch32_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_vgg16_sync_batch32_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_sync_batch32_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_sync_batch32_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_sync_batch32_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_sync_batch32/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_sync_batch32/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_sync_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg16_sync_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg16_sync_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=vgg16 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg16_sync_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=vgg16 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg16_sync_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=vgg16 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg16_sync_xla_w1.json --graph_file=/benchmarks/imagenet_vgg16_sync_xla_w1.pbtxt 2> imagenet_vgg16_sync_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=true --model=vgg16 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg16_sync_xla_w2.json --graph_file=/benchmarks/imagenet_vgg16_sync_xla_w2.pbtxt 2> imagenet_vgg16_sync_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_sync_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_sync_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_sync_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_vgg16_sync_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_sync_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_sync_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_sync_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_sync_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_sync_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_async_xla
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg16_async_xla_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg16_async_xla_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=vgg16 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg16_async_xla_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=vgg16 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg16_async_xla_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=vgg16 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg16_async_xla_w1.json --graph_file=/benchmarks/imagenet_vgg16_async_xla_w1.pbtxt 2> imagenet_vgg16_async_xla_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --xla=True --cross_replica_sync=false --model=vgg16 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg16_async_xla_w2.json --graph_file=/benchmarks/imagenet_vgg16_async_xla_w2.pbtxt 2> imagenet_vgg16_async_xla_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_async_xla_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_async_xla_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg16_async_xla_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_vgg16_async_xla_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_async_xla_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_async_xla_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg16_async_xla_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_async_xla/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg16_async_xla/

mkdir /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg19_sync_use_fp16
nohup /home/ubuntu/cyshin/benchmarks/NVML > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg19_sync_use_fp16_gpu.txt 2> /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/nvml/imagenet_vgg19_sync_use_fp16_gpu.err &
sleep 1s;
#------------------Start Time Stamping-------------
STARTTIME=$(date +%s%N)
#------------------Training Section-----------------
sudo docker exec bench_ps1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=vgg19 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg19_sync_use_fp16_corelog_ps1.txt &
sudo docker exec bench_ps2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=ps --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=vgg19 --data_name=imagenet --num_batches=11 --display_every=1  2> imagenet_vgg19_sync_use_fp16_corelog_ps2.txt &
W1STARTTIME=$(date +%s%N)
W1ENDTIME=0
sudo docker exec bench_w1 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=0 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=vgg19 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg19_sync_use_fp16_w1.json --graph_file=/benchmarks/imagenet_vgg19_sync_use_fp16_w1.pbtxt 2> imagenet_vgg19_sync_use_fp16_corelog_w1.txt &
W2STARTTIME=$(date +%s%N)
W2ENDTIME=0
sudo docker exec bench_w2 /root/anaconda3/envs/tfbuild/bin/python3.6 /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py --job_name=worker --task_index=1 --variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 --worker_hosts=172.20.3.4:5304,172.20.3.5:5306 --batch_size=64 --use_fp16=true --cross_replica_sync=true --model=vgg19 --data_name=imagenet  --num_batches=11 --display_every=1 --trace_file=/benchmarks/imagenet_vgg19_sync_use_fp16_w2.json --graph_file=/benchmarks/imagenet_vgg19_sync_use_fp16_w2.pbtxt 2> imagenet_vgg19_sync_use_fp16_corelog_w2.txt &
#--------------Wait for end of Training-------------
DURATION=0
while [ $DURATION -lt 300000000000 ]
do
NOW=$(date +%s%N)
DURATION=$(($NOW - $STARTTIME))
a=`ps -ef | grep "job_name=worker --task_index=0" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
b=`ps -ef | grep "job_name=worker --task_index=1" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;
if [ -z "$a" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi
if [ -z "$b" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi
if [ -z "$a" ] && [ -z "$b" ]; then ENDTIME=$NOW; break; fi
done
sleep 1s;
echo "TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))" > /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg19_sync_use_fp16_time.txt
echo "W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg19_sync_use_fp16_w1_time.txt
echo "W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))" | sudo tee -a  /home/ubuntu/cyshin/benchmarks/xonar_results_gpu//time/imagenet_vgg19_sync_use_fp16_w2_time.txt
sleep 1s;
#--------------------kill NVML------------------
sudo pkill NVML
sudo kill -9 `ps -ef | grep NVML | awk '{print $2}'`;
#--------------------kill python------------------
PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps1 kill -9 $PYTHONPID
PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')
sudo docker exec bench_ps2 kill -9 $PYTHONPID
sleep 1s;
#------------------move core log-------------------
mv imagenet_vgg19_sync_use_fp16_corelog_ps1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg19_sync_use_fp16_corelog_ps2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg19_sync_use_fp16_corelog_w1.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
mv imagenet_vgg19_sync_use_fp16_corelog_w2.txt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/corelog/
#------------------move pbtxt, json-------------------
mv /home/ubuntu/cyshin/benchmarks/*.json /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg19_sync_use_fp16/
mv /home/ubuntu/cyshin//benchmarks/*.pbtxt /home/ubuntu/cyshin/benchmarks/xonar_results_gpu/imagenet_vgg19_sync_use_fp16/

