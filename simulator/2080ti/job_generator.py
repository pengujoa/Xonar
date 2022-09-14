import os
import sys
from random import randint


def generate_scripts():
    # out of memory error models
    oom_model_list = ['cifar10_densenet100_k12_sync_batch512','cifar10_densenet100_k12_async_batch512',
                      'cifar10_densenet100_k24_sync_batch256','cifar10_densenet100_k24_async_batch256',
                      'cifar10_densenet100_k24_sync_batch512','cifar10_densenet100_k24_async_batch512',
                      'cifar10_densenet100_k12_sync_batch256','cifar10_densenet100_k24_async_batch128',
                      'cifar10_densenet100_k12_async_batch256','cifar10_densenet100_k24_sync_batch128']

    Params_dict = {"batch32": "--batch_size=32 ", "batch64": "--batch_size=64 ", "batch128": "--batch_size=128 ",
                   "batch256": "--batch_size=256 ", "batch512": "--batch_size=512 ",
                   "usefp16": "--batch_size=64 --use_fp16=true ",
                   "optMomentum": "--batch_size=64 --optimizer=momentum ",
                   "optRmsprop": "--batch_size=64 --optimizer=rmsprop ",
                   "dataFormat": "--batch_size=64 --data_format=NCHW ",
                   "winograd": "--batch_size=64 --winograd_nonfused=false ",
                   "xla": "--batch_size=64 --xla=True "}

    Synchronization_dict = {"sync": "--cross_replica_sync=true ", "async": "--cross_replica_sync=false "}

    Model_dict = {"densenet40k12": "densenet40_k12", "densenet100k12": "densenet100_k12",
                  "densenet100k24": "densenet100_k24", "resnet20": "resnet20", "resnet20v2": "resnet20_v2",
                  "resnet32": "resnet32", "resnet32v2": "resnet32_v2", "resnet44": "resnet44",
                  "resnet44v2": "resnet44_v2", "resnet56": "resnet56", "resnet56v2": "resnet56_v2",
                  "resnet110": "resnet110", "resnet110v2": "resnet110_v2", "alexnet": "alexnet", "vgg16": "vgg16",
                  "overfeat": "overfeat", "inception3": "inception3", "inception4": "inception4", "resnet50": "resnet50",
                  "resnet50v2": "resnet50_v2", "resnet101": "resnet101", "resnet101v2": "resnet101_v2",
                  "resnet152": "resnet152", "resnet152v2": "resnet152_v2", "alexnet": "alexnet",
                  "googlenet": "googlenet", "vgg11": "vgg11", "vgg16": "vgg16", "vgg19": "vgg19"}

    job, option = random_job()
    while job in oom_model_list:
        job, option = random_job()

    path = "/benchmarks/scripts/tf_cnn_benchmarks/tf_cnn_benchmarks.py "

    #------------ slot 1 ------------#
    cluster_spec = "--variable_update=parameter_server --ps_hosts=172.20.3.1:5300,172.20.3.2:5302 " \
                   "--worker_hosts=172.20.3.4:5304,172.20.3.5:5306 "

    ps1_command = path + "--job_name=ps " + "--task_index=0 " + "--slot_index=1 " + cluster_spec
    ps2_command = path + "--job_name=ps " + "--task_index=1 " + "--slot_index=1 " + cluster_spec
    w1_command = path + "--job_name=worker " + "--task_index=0 " + "--slot_index=1 " + cluster_spec
    w2_command = path + "--job_name=worker " + "--task_index=1 " + "--slot_index=1 " + cluster_spec

    command = []
    command.append(
        ps1_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")
    command.append(
        ps2_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")
    command.append(
        w1_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")
    command.append(
        w2_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")

    script_path = "random_job_scripts/"
    script_name = script_path + "1_" + job + ".sh"
    script_file = open(script_name, 'w')
    python_path = "/root/anaconda3/envs/tfbuild/bin/python3.6"

    print("#!/bin/bash", file=script_file)
    print("# How to use: sudo bash DDL_command.sh", file=script_file)

    print("#------------------Training Section-----------------", file=script_file)
    print("sudo docker exec bench_ps1", python_path, command[0], file=script_file)
    print("sudo docker exec bench_ps2", python_path, command[1], file=script_file)
    print("sudo docker exec bench_w1", python_path, command[2], file=script_file)
    print("sudo docker exec bench_w2", python_path, command[3], file=script_file)

    print("#--------------Wait for end of Training-------------", file=script_file)
    print("a=`ps -ef | grep 'job_name=worker --task_index=0 --slot_index=1' | awk '{print $2}' | sed -n '1p'`;", file=script_file)
    print("b=`ps -ef | grep 'job_name=worker --task_index=0 --slot_index=1' | awk '{print $2}' | sed -n '2p'`;", file=script_file)
    print("c=`ps -ef | grep 'job_name=worker --task_index=1 --slot_index=1' | awk '{print $2}' | sed -n '1p'`;", file=script_file)
    print("d=`ps -ef | grep 'job_name=worker --task_index=1 --slot_index=1' | awk '{print $2}' | sed -n '2p'`;", file=script_file)
    print("wait $a;", file=script_file)
    print("wait $b;", file=script_file)
    print("wait $c;", file=script_file)
    print("wait $d;", file=script_file)

    print("#--------------------kill python------------------", file=script_file)
    print("PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')", file=script_file)
    print("sudo docker exec bench_ps1 kill -9 $PYTHONPID", file=script_file)
    print("PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')", file=script_file)
    print("sudo docker exec bench_ps2 kill -9 $PYTHONPID", file=script_file)
    print("sleep 1s;", file=script_file)

    print("sudo docker restart bench_ps1", file=script_file)
    print("sudo docker restart bench_ps2", file=script_file)

    print("", file=script_file)

    script_file.close()

    # ------------ slot 2 ------------#
    cluster_spec = "--variable_update=parameter_server --ps_hosts=172.20.3.6:5308,172.20.3.7:5310 " \
                   "--worker_hosts=172.20.3.8:5312,172.20.3.9:5314 "

    ps1_command = path + "--job_name=ps " + "--task_index=0 " + "--slot_index=2 " + cluster_spec
    ps2_command = path + "--job_name=ps " + "--task_index=1 " + "--slot_index=2 " + cluster_spec
    w1_command = path + "--job_name=worker " + "--task_index=0 " + "--slot_index=2 " + cluster_spec
    w2_command = path + "--job_name=worker " + "--task_index=1 " + "--slot_index=2 " + cluster_spec

    command = []
    command.append(
        ps1_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")
    command.append(
        ps2_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")
    command.append(
        w1_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")
    command.append(
        w2_command + Params_dict[option["params"]] + Synchronization_dict[option["sync_method"]]
        + "--model=" + Model_dict[option["model"]] + " --data_name=" + option["dataset"] + " --num_batches=200 --display_every=1 &")

    script_path = "random_job_scripts/"
    script_name = script_path + "2_" + job + ".sh"
    script_file = open(script_name, 'w')
    python_path = "/root/anaconda3/envs/tfbuild/bin/python3.6"

    print("#!/bin/bash", file=script_file)
    print("# How to use: sudo bash DDL_command.sh", file=script_file)

    print("#------------------Training Section-----------------", file=script_file)
    print("sudo docker exec bench_ps3", python_path, command[0], file=script_file)
    print("sudo docker exec bench_ps4", python_path, command[1], file=script_file)
    print("sudo docker exec bench_w3", python_path, command[2], file=script_file)
    print("sudo docker exec bench_w4", python_path, command[3], file=script_file)

    print("#--------------Wait for end of Training-------------", file=script_file)
    print("a=`ps -ef | grep 'job_name=worker --task_index=0 --slot_index=2' | awk '{print $2}' | sed -n '1p'`;", file=script_file)
    print("b=`ps -ef | grep 'job_name=worker --task_index=0 --slot_index=2' | awk '{print $2}' | sed -n '2p'`;", file=script_file)
    print("c=`ps -ef | grep 'job_name=worker --task_index=1 --slot_index=2' | awk '{print $2}' | sed -n '1p'`;", file=script_file)
    print("d=`ps -ef | grep 'job_name=worker --task_index=1 --slot_index=2' | awk '{print $2}' | sed -n '2p'`;", file=script_file)
    print("wait $a;", file=script_file)
    print("wait $b;", file=script_file)
    print("wait $c;", file=script_file)
    print("wait $d;", file=script_file)

    print("#--------------------kill python------------------", file=script_file)
    print("PYTHONPID=$(sudo docker exec bench_ps1 ps -ef | grep python | awk '{print $2}')", file=script_file)
    print("sudo docker exec bench_ps3 kill -9 $PYTHONPID", file=script_file)
    print("PYTHONPID=$(sudo docker exec bench_ps2 ps -ef | grep python | awk '{print $2}')", file=script_file)
    print("sudo docker exec bench_ps4 kill -9 $PYTHONPID", file=script_file)
    print("sleep 1s;", file=script_file)

    print("sudo docker restart bench_ps3", file=script_file)
    print("sudo docker restart bench_ps4", file=script_file)

    print("", file=script_file)

    script_file.close()

    return job


def random_job():
    Dataset_list = ["cifar10"]

    CIFAR10_model_list = ["densenet40k12", "densenet100k12", "densenet100k24",
                          "resnet20", "resnet20v2", "resnet32", "resnet32v2", "resnet44", "resnet44v2",
                          "resnet56", "resnet56v2", "resnet110", "resnet110v2",
                          "alexnet", "vgg16"]

    ImageNet_model_list = ["overfeat", "inception3", "inception4",
                           "resnet50", "resnet50v2", "resnet101", "resnet101v2", "resnet152", "resnet152v2",
                           "alexnet", "googlenet", "vgg11", "vgg16", "vgg19"]

    Synchronization_list = ["sync", "async"]

    # batch64 is same as Default
    Params_list = ["batch32", "batch64", "batch128", "batch256", "batch512", "usefp16", "optMomentum", "optRmsprop", "dataFormat",
                   "winograd", "xla"]

    job = ""
    option = {}
    # random dataset
    dataset = Dataset_list[0]
    job = job + dataset + "_"
    option["dataset"] = dataset
    # random model
    if dataset == "cifar10":
        model = CIFAR10_model_list[randint(0, len(CIFAR10_model_list) - 1)]
        job = job + model + "_"
        option["model"] = model
    elif dataset == "imagenet":
        model = ImageNet_model_list[randint(0, len(ImageNet_model_list) - 1)]
        job = job + model + "_"
        option["model"] = model
    # random sync_mothod
    sync_method = Synchronization_list[randint(0, 1)]
    job = job + sync_method + "_"
    option["sync_method"] = sync_method
    # random params
    params = Params_list[randint(0, len(Params_list) - 1)]
    job = job + params
    option["params"] = params

    return job, option
