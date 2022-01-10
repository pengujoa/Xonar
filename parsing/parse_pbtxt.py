import tensorflow as tf
from google.protobuf import text_format

HOUR = 3600
MINUTE = 60
WARM_UP = 10
ITERATIONS = 100

# w1, w2에서 생성한 new pbtxt -> 결국 동일함.

def import_pbtxt(file):
    with open(file) as f:
        pbtxt = f.read()
        graph_def = text_format.Parse(pbtxt, tf.compat.v1.GraphDef(), allow_field_number=1)
        return graph_def


def classify_node(node_list, n_w, n_ps):
    # ps는 CPU만 사용
    ps_cpu_send_rpc = [{} for _ in range(n_ps)]
    ps_cpu_recv_rpc = [{} for _ in range(n_ps)]
    # worker는 CPU, GPU 사용
    w_cpu_send_rpc = [{} for _ in range(n_w)]
    w_cpu_recv_rpc = [{} for _ in range(n_w)]
    w_gpu_send_rpc = [{} for _ in range(n_w)]
    w_gpu_recv_rpc = [{} for _ in range(n_w)]

    for node in node_list:

        if node.op == "_Send":
            sender_info = str(node.attr["send_device"]).split("/")
            recver_info = str(node.attr["recv_device"]).split("/")
            sender_job = sender_info[1].split(":")[1]
            recver_job = recver_info[1].split(":")[1]
            sender_device = sender_info[4].split(":")[1]
            recver_device = recver_info[4].split(":")[1]
            sender_task_idx = int(sender_info[3].split(":")[1])
            recver_task_idx = int(recver_info[3].split(":")[1])
            if sender_job == "ps":
                if sender_job != recver_job or sender_task_idx != recver_task_idx:
                    ps_cpu_send_rpc[sender_task_idx][str(node.attr["tensor_name"]).split("\"")[1]] = node.name
                else:
                    # print("ps->ps인데, task까지 동일한 경우 존재. 즉 tensor 전송에 rpc 사용 안함.")
                    pass
            elif sender_job == "worker":
                if sender_job != recver_job or sender_task_idx != recver_task_idx:
                    if sender_device == "CPU":
                        w_cpu_send_rpc[sender_task_idx][str(node.attr["tensor_name"]).split("\"")[1]] = node.name
                    elif "GPU" == sender_device:
                        w_gpu_send_rpc[sender_task_idx][str(node.attr["tensor_name"]).split("\"")[1]] = node.name
                else: # worker cpu -> worker gpu 또는 worker gpu -> worker cpu
                    # print("w->w인데, task까지 동일한 경우 존재. 즉 tensor 전송에 rpc 사용 안함.")
                    # print(node.name)
                    pass

        elif node.op == "_Recv":
            sender_info = str(node.attr["send_device"]).split("/")
            recver_info = str(node.attr["recv_device"]).split("/")
            sender_job = sender_info[1].split(":")[1]
            recver_job = recver_info[1].split(":")[1]
            sender_device = sender_info[4].split(":")[1]
            recver_device = recver_info[4].split(":")[1]
            sender_task_idx = int(sender_info[3].split(":")[1])
            recver_task_idx = int(recver_info[3].split(":")[1])
            if recver_job == "ps":
                if sender_job != recver_job or sender_task_idx != recver_task_idx:
                    ps_cpu_recv_rpc[recver_task_idx][str(node.attr["tensor_name"]).split("\"")[1]] = node.name
                else:
                    # print("ps->ps인데, task까지 동일한 경우 존재. 즉 tensor 전송에 rpc 사용 안함.")
                    pass
            elif recver_job == "worker":
                if sender_job != recver_job or sender_task_idx != recver_task_idx:
                    if recver_device == "CPU":
                        # w_cpu_recv_rpc[recver_task_idx].append(str(node.attr["tensor_name"]))
                        w_cpu_recv_rpc[recver_task_idx][str(node.attr["tensor_name"]).split("\"")[1]] = node.name
                    elif recver_device == "GPU":
                        w_gpu_recv_rpc[recver_task_idx][str(node.attr["tensor_name"]).split("\"")[1]] = node.name
                        # w_gpu_recv_rpc[recver_task_idx].append(node.name)
                else: # worker cpu -> worker gpu 또는 worker gpu -> worker cpu
                    # print("w->w인데, task까지 동일한 경우 존재. 즉 tensor 전송에 rpc 사용 안함.")
                    # print(node.name)
                    pass

    print(len(ps_cpu_send_rpc[0]))
    print(len(ps_cpu_send_rpc[1]))
    print(len(w_cpu_send_rpc[0]))
    print(len(w_cpu_send_rpc[1]))
    print(len(w_gpu_send_rpc[0]))
    print(len(w_gpu_send_rpc[1]))

    print(len(ps_cpu_recv_rpc[0]))
    print(len(ps_cpu_recv_rpc[1]))
    print(len(w_cpu_recv_rpc[0]))
    print(len(w_cpu_recv_rpc[1]))
    print(len(w_gpu_recv_rpc[0]))
    print(len(w_gpu_recv_rpc[1]))

    return ps_cpu_send_rpc, w_cpu_send_rpc, w_gpu_send_rpc, ps_cpu_recv_rpc, w_cpu_recv_rpc, w_gpu_recv_rpc


if __name__ == '__main__':
    pbtxt = import_pbtxt("bench_log/new_imagenet_resnet101_v2_sync_batch64_w1.pbtxt")
    ps_cpu_send_rpc_1, w_cpu_send_rpc_1, w_gpu_send_rpc_1, ps_cpu_recv_rpc_1, w_cpu_recv_rpc_1, w_gpu_recv_rpc_1 = classify_node(pbtxt.node, 2, 2)
    print()
    pbtxt = import_pbtxt("bench_log/new_imagenet_resnet101_v2_sync_batch64_w2.pbtxt")
    ps_cpu_send_rpc_2, w_cpu_send_rpc_2, w_gpu_send_rpc_2, ps_cpu_recv_rpc_2, w_cpu_recv_rpc_2, w_gpu_recv_rpc_2 = classify_node(pbtxt.node, 2, 2)
    # print("--test--")
    # test = ps_cpu_send_rpc_1[0] + ps_cpu_send_rpc_2[0]
    # print("before: ", len(test))
    # print("after: ", len(list(set(test))))
    # print("--test--")
    # test = ps_cpu_send_rpc_1[1] + ps_cpu_send_rpc_2[1]
    # print("before: ", len(test))
    # print("after: ", len(list(set(test))))
    # print("--test--")
    # test = ps_cpu_recv_rpc_1[0] + ps_cpu_recv_rpc_2[0]
    # print("before: ", len(test))
    # print("after: ", len(list(set(test))))
    # print("--test--")
    # test = ps_cpu_recv_rpc_1[1] + ps_cpu_recv_rpc_2[1]
    # print("before: ", len(test))
    # print("after: ", len(list(set(test))))
    # print("-----")
    print(ps_cpu_recv_rpc_1[0])



