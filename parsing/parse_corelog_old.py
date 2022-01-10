HOUR = 3600
MINUTE = 60
WARM_UP = 10
ITERATIONS = 100

import parse_pbtxt


def parse_3timestamp(file_w1, file_ps1, file_ps2, w_cpu_send_rpc_1, w_gpu_send_rpc_1, w_cpu_recv_rpc_1, w_gpu_recv_rpc_1):
    raw_log = open(file_w1, 'r').read().split("New Step START\n")
    ps1_raw_log = open(file_ps1, 'r').read().split("\n")
    ps2_raw_log = open(file_ps2, 'r').read().split("\n")
    ps_log = ps1_raw_log + ps2_raw_log

    w_recv = {}
    w_recv.update(w_cpu_recv_rpc_1[0])
    w_recv.update(w_gpu_recv_rpc_1[0])

    w_send = {}
    w_send.update(w_cpu_send_rpc_1[0])
    w_send.update(w_gpu_send_rpc_1[0])

    raw_log_per_iter = []
    for i in range(WARM_UP + 1, WARM_UP + ITERATIONS + 1):
        raw_log_per_iter.append(raw_log[i].split("\n"))
        # print(len(raw_log_per_iter[i-WARM_UP-1]))

    send_time = []
    recv_time = []
    for log in raw_log_per_iter:

        out = ""
        count_send = 0
        count_recv = 0
        send_min_req_start = 2640866203200262
        send_max_req_start = 0
        send_min_resp_start = 2640866203200262
        send_max_resp_start = 0
        send_min_resp_end = 2640866203200262
        send_max_resp_end = 0

        min_req_start = 2640866203200262
        max_req_start = 0
        min_resp_start = 2640866203200262
        max_resp_start = 0
        min_resp_end = 2640866203200262
        max_resp_end = 0

        for s in log:
            if "send" in s:
                count_send += 1
                key = s.split(",")[1] + "," + s.split(",")[2]
                for ss in ps_log:
                    if key in ss:
                        out = out + "\n" + ss
                        try:
                            op_name = w_send[ss.split(",")[0].split(" ")[4]]
                            tensor_name = ss.split(",")[0].split(" ")[4]
                            send_dev = ss.split(",")[1]
                            recv_dev = ss.split(",")[2]
                            send_req_start = int(ss.split(",")[7])
                            send_resp_start = int(ss.split(",")[8])
                            tensor_id = int(ss.split(",")[9])
                            send_resp_end = int(ss.split(",")[10])
                            tensor_bytes = int(ss.split(",")[11])
                            # print("------")
                            # print("req_start:", send_req_start, " | resp_start - req_start:", send_resp_start - send_req_start)
                            # print("resp_start:", send_resp_start, " | resp_end - resp_start:", send_resp_end - send_resp_start)
                            # print("resp_end:", send_resp_end)
                            # print("tensor_name:", tensor_name, " ,bytes:", tensor_bytes)

                            if ("Const_" not in tensor_name) & ("Merge" not in tensor_name):
                                if send_req_start > send_max_req_start:
                                    send_max_req_start = send_req_start
                                if send_req_start < send_min_req_start:
                                    send_min_req_start = send_req_start
                                if send_resp_start > send_max_resp_start:
                                    send_max_resp_start = send_resp_start
                                if send_resp_start < send_min_resp_start:
                                    send_min_resp_start = send_resp_start
                                if send_resp_end > send_max_resp_end:
                                    send_max_resp_end = send_resp_end
                                if send_resp_end < send_min_resp_end:
                                    send_min_resp_end = send_resp_end

                        except KeyError:
                            # pass
                            print("error: ", s.split(",")[0].split(" ")[4])

            elif "RecvTensorAsync" in s:
                count_recv += 1
                try:
                    op_name = w_recv[s.split(",")[0].split(" ")[4]]
                    tensor_name = s.split(",")[0].split(" ")[4]
                    send_dev = s.split(",")[1]
                    recv_dev = s.split(",")[2]
                    req_start = int(s.split(",")[7])
                    resp_start = int(s.split(",")[8])
                    tensor_id = int(s.split(",")[9])
                    resp_end = int(s.split(",")[10])
                    tensor_bytes = int(s.split(",")[11])
                    # print("------")
                    # print("req_start:", req_start, " | resp_start - req_start:", resp_start - req_start)
                    # print("resp_start:", resp_start, " | resp_end - resp_start:", resp_end - resp_start)
                    # print("resp_end:", resp_end)
                    # print("tensor_name:", tensor_name, " ,bytes:", tensor_bytes)

                    if ("NoOp" not in tensor_name) & ("AssignAdd" not in tensor_name):
                        if req_start > max_req_start:
                            max_req_start = req_start
                        if req_start < min_req_start:
                            min_req_start = req_start
                        if resp_start > max_resp_start:
                            max_resp_start = resp_start
                        if resp_start < min_resp_start:
                            min_resp_start = resp_start
                        if resp_end > max_resp_end:
                            max_resp_end = resp_end
                        if resp_end < min_resp_end:
                            min_resp_end = resp_end

                except KeyError:
                    # pass
                    print("error: ", s.split(",")[0].split(" ")[4])

        print("----")
        print("min_req_start",min_req_start)
        print("max_req_start",max_req_start)
        print("diff", max_req_start - min_req_start)
        print("----")
        print("min_resp_start",max_req_start)
        print("max_resp_start",max_resp_start)
        print("diff", max_resp_start - min_resp_start)
        print("----")
        print("min_resp_end",min_resp_end)
        print("max_resp_end",max_resp_end)
        print("diff", max_resp_end - min_resp_end)
        print("----")
        print("send_min_req_start",send_min_req_start)
        print("send_max_req_start",send_max_req_start)
        print("diff", send_max_req_start - send_min_req_start)
        print("----")
        print("send_min_resp_start",send_max_req_start)
        print("send_max_resp_start",send_max_resp_start)
        print("diff", send_max_resp_start - send_min_resp_start)
        print("----")
        print("send_min_resp_end",send_min_resp_end)
        print("send_max_resp_end",send_max_resp_end)
        print("diff", send_max_resp_end - send_min_resp_end)
        print("----")

        recv_time.append(max_resp_end - min_resp_end)
        send_time.append(send_max_resp_end - send_min_resp_end)

    # print(raw_log_per_iter[51])

    print(recv_time)
    print(send_time)
    print(len(recv_time))
    print(len(send_time))
    print(sum(recv_time)/len(recv_time))
    print(sum(send_time) / len(send_time))

    print(len(raw_log_per_iter[51]))
    print(count_send)
    print(count_recv)

    f = open('out.txt', 'w')

    f.write(out)
    f.close()


if __name__ == '__main__':
    pbtxt = parse_pbtxt.import_pbtxt("bench_log/new_imagenet_resnet101_v2_sync_batch64_w1.pbtxt")
    ps_cpu_send_rpc_1, w_cpu_send_rpc_1, w_gpu_send_rpc_1, ps_cpu_recv_rpc_1, w_cpu_recv_rpc_1, w_gpu_recv_rpc_1 = \
        parse_pbtxt.classify_node(pbtxt.node, 2, 2)
    parse_3timestamp("bench_log/core_log_3timestamp_w1.txt","bench_log/core_log_3timestamp_ps1.txt","bench_log/core_log_3timestamp_ps2.txt", w_cpu_send_rpc_1, w_gpu_send_rpc_1, w_cpu_recv_rpc_1, w_gpu_recv_rpc_1)


