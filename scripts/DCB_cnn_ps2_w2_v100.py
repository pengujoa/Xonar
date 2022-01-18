# Example: cifar10, resnet20, sync
# ps: python /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py
#     --batch_size=64 --model=resnet20 --variable_update=parameter_server
#     --data_format=NHWC --job_name=ps
#     --ps_hosts=172.20.1.1:5100 --worker_hosts=172.20.1.2:5102,172.20.1.3:5104
#     --data_name=cifar10 --cross_replica_sync=true
# w1: python /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py
#     --batch_size=64 --model=resnet20 --variable_update=parameter_server
#     --data_format=NHWC --job_name=worker
#     --ps_hosts=172.20.1.1:5100 --worker_hosts=172.20.1.2:5102,172.20.1.3:5104
#     --data_name=cifar10 --cross_replica_sync=true --task_index=0
# w2: python /benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py
#     --batch_size=64 --model=resnet20 --variable_update=parameter_server
#     --data_format=NHWC --job_name=worker
#     --ps_hosts=172.20.1.1:5100 --worker_hosts=172.20.1.2:5102,172.20.1.3:5104
#     --data_name=cifar10 --cross_replica_sync=true --task_index=1
import sys


def cnn_model_name_builder():
    Dataset = ("cifar10, imagenet")

    CIFAR10_model = ("densenet40_k12", "densenet100_k12", "densenet100_k24",
                     "resnet20", "resnet20_v2", "resnet32", "resnet32_v2", "resnet44", "resnet44_v2",
                     "resnet56", "resnet56_v2", "resnet110", "resnet110_v2",
                     "alexnet", "vgg16")

    ImageNet_model = ("overfeat", "inception3", "inception4",
                      "resnet50", "resnet50_v2", "resnet101", "resnet101_v2", "resnet152", "resnet152_v2",
                      "alexnet", "googlenet", "vgg11", "vgg16", "vgg19")

    Synchronization = {"sync": "--cross_replica_sync=true ", "async": "--cross_replica_sync=false "}

    # batch64 is same as Default
    Params = {"batch32": "--batch_size=32 ", "batch64": "--batch_size=64 ", "batch128": "--batch_size=128 ",
              "batch256": "--batch_size=256 ", "batch512": "--batch_size=512 ",
              "use_fp16": "--batch_size=64 --use_fp16=true ",
              "optMomentum": "--batch_size=64 --optimizer=momentum ",
              "optRmsprop": "--batch_size=64 --optimizer=rmsprop ",
              "dataFormat": "--batch_size=64 --data_format=NCHW ",
              "winograd": "--batch_size=64 --winograd_nonfused=false ",
              "xla": "--batch_size=64 --xla=True "}

    path = "/benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py "
    cluster_spec = "--variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 " \
                   "--worker_hosts=172.20.3.4:5304,172.20.3.5:5306 "

    ps1_command = path + "--job_name=ps " + "--task_index=0 " + cluster_spec
    ps2_command = path + "--job_name=ps " + "--task_index=1 " + cluster_spec
    w1_command = path + "--job_name=worker " + "--task_index=0 " + cluster_spec
    w2_command = path + "--job_name=worker " + "--task_index=1 " + cluster_spec

    # Dataset = cifar10
    _cifar10_command_dict = {}
    for model in CIFAR10_model:
        for sync_method, sync_option in Synchronization.items():
            for parameter, params_option in Params.items():
                # commnad_key: dataset + CNN model name + hyperparameter options
                command_key = "cifar10" + "_" + model + "_" + sync_method + "_" + parameter
                # command_value: DDL command for PS, Worker
                command_value = []
                command_value.append(
                    ps1_command + params_option + sync_option + "--model=" + model + " --data_name=cifar10 --num_batches=11 --display_every=1 ")
                command_value.append(
                    ps2_command + params_option + sync_option + "--model=" + model + " --data_name=cifar10 --num_batches=11 --display_every=1 ")
                command_value.append(
                    w1_command + params_option + sync_option + "--model=" + model + " --data_name=cifar10  --num_batches=11 --display_every=1 "
                    + "--trace_file=/benchmarks/" + command_key + "_w1.json "
                    + "--graph_file=/benchmarks/" + command_key + "_w1.pbtxt")
                command_value.append(
                    w2_command + params_option + sync_option + "--model=" + model + " --data_name=cifar10  --num_batches=11 --display_every=1 "
                    + "--trace_file=/benchmarks/" + command_key + "_w2.json "
                    + "--graph_file=/benchmarks/" + command_key + "_w2.pbtxt")
                _cifar10_command_dict[command_key] = command_value

    # Dataset = imagenet
    _imagenet_command_dict = {}
    for model in ImageNet_model:
        for sync_method, sync_option in Synchronization.items():
            for parameter, params_option in Params.items():
                # commnad_key: dataset + CNN model name + hyperparameter options
                command_key = "imagenet" + "_" + model + "_" + sync_method + "_" + parameter
                # command_value: DDL command for PS, Worker
                command_value = []
                command_value.append(
                    ps1_command + params_option + sync_option + "--model=" + model + " --data_name=imagenet --num_batches=11 --display_every=1 ")
                command_value.append(
                    ps2_command + params_option + sync_option + "--model=" + model + " --data_name=imagenet --num_batches=11 --display_every=1 ")
                command_value.append(
                    w1_command + params_option + sync_option + "--model=" + model + " --data_name=imagenet  --num_batches=11 --display_every=1 "
                    + "--trace_file=/benchmarks/" + command_key + "_w1.json "
                    + "--graph_file=/benchmarks/" + command_key + "_w1.pbtxt")
                command_value.append(
                    w2_command + params_option + sync_option + "--model=" + model + " --data_name=imagenet  --num_batches=11 --display_every=1 "
                    + "--trace_file=/benchmarks/" + command_key + "_w2.json "
                    + "--graph_file=/benchmarks/" + command_key + "_w2.pbtxt")
                _imagenet_command_dict[command_key] = command_value

    # out of memory error
    _cifar10_command_dict.pop('cifar10_densenet100_k12_sync_batch512')
    _cifar10_command_dict.pop('cifar10_densenet100_k12_async_batch512')

    _cifar10_command_dict.pop('cifar10_densenet100_k24_sync_batch256')
    _cifar10_command_dict.pop('cifar10_densenet100_k24_async_batch256')
    _cifar10_command_dict.pop('cifar10_densenet100_k24_sync_batch512')
    _cifar10_command_dict.pop('cifar10_densenet100_k24_async_batch512')

    _imagenet_command_dict.pop('imagenet_resnet50_sync_batch512')
    _imagenet_command_dict.pop('imagenet_resnet50_async_batch512')
    _imagenet_command_dict.pop('imagenet_resnet50_v2_sync_batch512')
    _imagenet_command_dict.pop('imagenet_resnet50_v2_async_batch512')

    _imagenet_command_dict.pop('imagenet_resnet101_sync_batch256')
    _imagenet_command_dict.pop('imagenet_resnet101_async_batch256')
    _imagenet_command_dict.pop('imagenet_resnet101_v2_sync_batch256')
    _imagenet_command_dict.pop('imagenet_resnet101_v2_async_batch256')

    _imagenet_command_dict.pop('imagenet_resnet101_sync_batch512')
    _imagenet_command_dict.pop('imagenet_resnet101_async_batch512')
    _imagenet_command_dict.pop('imagenet_resnet101_v2_sync_batch512')
    _imagenet_command_dict.pop('imagenet_resnet101_v2_async_batch512')

    _imagenet_command_dict.pop('imagenet_resnet152_sync_batch256')
    _imagenet_command_dict.pop('imagenet_resnet152_async_batch256')
    _imagenet_command_dict.pop('imagenet_resnet152_v2_sync_batch256')
    _imagenet_command_dict.pop('imagenet_resnet152_v2_async_batch256')

    _imagenet_command_dict.pop('imagenet_resnet152_sync_batch512')
    _imagenet_command_dict.pop('imagenet_resnet152_async_batch512')
    _imagenet_command_dict.pop('imagenet_resnet152_v2_sync_batch512')
    _imagenet_command_dict.pop('imagenet_resnet152_v2_async_batch512')

    _imagenet_command_dict.pop('imagenet_inception3_sync_batch512')
    _imagenet_command_dict.pop('imagenet_inception3_async_batch512')

    _imagenet_command_dict.pop('imagenet_inception4_sync_batch256')
    _imagenet_command_dict.pop('imagenet_inception4_async_batch256')
    _imagenet_command_dict.pop('imagenet_inception4_sync_batch512')
    _imagenet_command_dict.pop('imagenet_inception4_async_batch512')

    _imagenet_command_dict.pop('imagenet_vgg11_sync_batch512')
    _imagenet_command_dict.pop('imagenet_vgg11_async_batch512')
    _imagenet_command_dict.pop('imagenet_vgg16_sync_batch512')
    _imagenet_command_dict.pop('imagenet_vgg16_async_batch512')
    _imagenet_command_dict.pop('imagenet_vgg19_sync_batch512')
    _imagenet_command_dict.pop('imagenet_vgg19_async_batch512')

    return _cifar10_command_dict, _imagenet_command_dict


if __name__ == '__main__':
    cifar10_command_dict, imagenet_command_dict = cnn_model_name_builder()
    sys.stdout = open('DDL_command_cnn_ps2_w2_trace_resource.sh', 'w')
    python_path = "/root/anaconda3/envs/tfbuild/bin/python3.6"
    result_path = "/home/ubuntu/cyshin/benchmarks/xonar_results/"

    print("#!/bin/bash")
    print("# How to use: sudo bash DDL_command.sh")

    for key, value in cifar10_command_dict.items():
        result_dir = result_path + key
        print("mkdir", result_dir)
        print("sleep 1s;")

        print("#------------------Start Time Stamping-------------")
        print("STARTTIME=$(date +%s%N)")

        print("#------------------Training Section-----------------")
        print("sudo docker exec bench_ps1", python_path, value[0], "2> " + key + "_corelog_ps1.txt &")
        print("sudo docker exec bench_ps2", python_path, value[1], "2> " + key + "_corelog_ps2.txt &")
        print("W1STARTTIME=$(date +%s%N)")
        print("W1ENDTIME=0")
        print("sudo docker exec bench_w1", python_path, value[2], "2> " + key + "_corelog_w1.txt &")
        print("W2STARTTIME=$(date +%s%N)")
        print("W2ENDTIME=0")
        print("sudo docker exec bench_w2", python_path, value[3], "2> " + key + "_corelog_w2.txt &")

        print("#--------------Wait for end of Training-------------")
        print("DURATION=0")
        print("while [ $DURATION -lt 300000000000 ]")
        print("do")
        print("NOW=$(date +%s%N)")
        print("DURATION=$(($NOW - $STARTTIME))")
        print(
            "a=`ps -ef | grep \"job_name=worker --task_index=0\" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;")
        print(
            "b=`ps -ef | grep \"job_name=worker --task_index=1\" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;")
        print("if [ -z \"$a\" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi")
        print("if [ -z \"$b\" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi")
        print("if [ -z \"$a\" ] && [ -z \"$b\" ]; then ENDTIME=$NOW; break; fi")
        print("done")
        print("sleep 1s;")

        print("echo \"TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))\" >", result_path + "/time/" + key + "_time.txt")
        print("echo \"W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))\" | sudo tee -a ",
              result_path + "/time/" + key + "_w1_time.txt")
        print("echo \"W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))\" | sudo tee -a ",
              result_path + "/time/" + key + "_w2_time.txt")

        print("sleep 1s;")

        print("#--------------------kill python------------------")
        print("PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')")
        print("sudo docker exec bench_ps1 kill -9 $PYTHONPID")
        print("PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')")
        print("sudo docker exec bench_ps2 kill -9 $PYTHONPID")
        # print("sudo docker exec bench_w1 kill -9 `ps -ef | grep python | awk '{print $2}'`;")
        # print("sudo docker exec bench_w2 kill -9 `ps -ef | grep python | awk '{print $2}'`;")
        print("sleep 1s;")

        print("#------------------move core log-------------------")
        print("mv " + key + "_corelog_ps1.txt", result_path + "corelog/")
        print("mv " + key + "_corelog_ps2.txt", result_path + "corelog/")
        print("mv " + key + "_corelog_w1.txt", result_path + "corelog/")
        print("mv " + key + "_corelog_w2.txt", result_path + "corelog/")
        # print("mv *" + key + "*", result_dir + "/")

        print("#------------------move pbtxt, json-------------------")
        print("mv /home/ubuntu/cyshin/benchmarks/*.json", result_dir + "/")
        print("mv /home/ubuntu/cyshin//benchmarks/*.pbtxt", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w1.json", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w2.json", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w1.pbtxt", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w2.pbtxt", result_dir + "/")

        print()

    for key, value in imagenet_command_dict.items():
        result_dir = result_path + key
        print("mkdir", result_dir)
        print("sleep 1s;")

        print("#------------------Start Time Stamping-------------")
        print("STARTTIME=$(date +%s%N)")

        print("#------------------Training Section-----------------")
        print("sudo docker exec bench_ps1", python_path, value[0], "2> " + key + "_corelog_ps1.txt &")
        print("sudo docker exec bench_ps2", python_path, value[1], "2> " + key + "_corelog_ps2.txt &")
        print("W1STARTTIME=$(date +%s%N)")
        print("W1ENDTIME=0")
        print("sudo docker exec bench_w1", python_path, value[2], "2> " + key + "_corelog_w1.txt &")
        print("W2STARTTIME=$(date +%s%N)")
        print("W2ENDTIME=0")
        print("sudo docker exec bench_w2", python_path, value[3], "2> " + key + "_corelog_w2.txt &")

        print("#--------------Wait for end of Training-------------")
        print("DURATION=0")
        print("while [ $DURATION -lt 300000000000 ]")
        print("do")
        print("NOW=$(date +%s%N)")
        print("DURATION=$(($NOW - $STARTTIME))")
        print(
            "a=`ps -ef | grep \"job_name=worker --task_index=0\" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;")
        print(
            "b=`ps -ef | grep \"job_name=worker --task_index=1\" |grep -v color | grep -v grep | awk '{print $2}' | sed -n '1p'`;")
        print("if [ -z \"$a\" ] && [ $W1ENDTIME -eq 0 ]; then W1ENDTIME=$NOW; fi")
        print("if [ -z \"$b\" ] && [ $W2ENDTIME -eq 0 ]; then W2ENDTIME=$NOW; fi")
        print("if [ -z \"$a\" ] && [ -z \"$b\" ]; then ENDTIME=$NOW; break; fi")
        print("done")
        print("sleep 1s;")

        print("echo \"TOTAL: $(($(($ENDTIME - $STARTTIME))/1000000))\" >", result_path + "/time/" + key + "_time.txt")
        print("echo \"W1: $(($(($W1ENDTIME - $W1STARTTIME))/1000000))\" | sudo tee -a ",
              result_path + "/time/" + key + "_w1_time.txt")
        print("echo \"W2: $(($(($W2ENDTIME - $W2STARTTIME))/1000000))\" | sudo tee -a ",
              result_path + "/time/" + key + "_w2_time.txt")

        print("sleep 1s;")

        print("#--------------------kill python------------------")
        print("PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')")
        print("sudo docker exec bench_ps1 kill -9 $PYTHONPID")
        print("PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')")
        print("sudo docker exec bench_ps2 kill -9 $PYTHONPID")
        # print("sudo docker exec bench_w1 kill -9 `ps -ef | grep python | awk '{print $2}'`;")
        # print("sudo docker exec bench_w2 kill -9 `ps -ef | grep python | awk '{print $2}'`;")
        print("sleep 1s;")

        print("#------------------move core log-------------------")
        print("mv " + key + "_corelog_ps1.txt", result_path + "corelog/")
        print("mv " + key + "_corelog_ps2.txt", result_path + "corelog/")
        print("mv " + key + "_corelog_w1.txt", result_path + "corelog/")
        print("mv " + key + "_corelog_w2.txt", result_path + "corelog/")
        # print("mv *" + key + "*", result_dir + "/")

        print("#------------------move pbtxt, json-------------------")
        print("mv /home/ubuntu/cyshin/benchmarks/*.json", result_dir + "/")
        print("mv /home/ubuntu/cyshin//benchmarks/*.pbtxt", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w1.json", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w2.json", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w1.pbtxt", result_dir + "/")
        # print("mv /benchmarks/" + key + "_w2.pbtxt", result_dir + "/")

        print()