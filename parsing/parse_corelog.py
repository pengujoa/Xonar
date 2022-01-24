from parsing import parse_pbtxt as pb

WARM_UP = 10
ITERATIONS = 10
MAX_VAL = 9999999999999999
HOUR = 3600
MINUTE = 60


def parse_corelog(ddl_model, log_dir, pbtxt_dir, time_dir, nvml_dir, num_ps, num_w, is_worker, w_gpu_idx):
    print(len(w_gpu_idx))
    result = [[] for _ in range(num_w)]
    if is_worker:
        ps_log = []
        for ps_idx in range(1, num_ps + 1):
            ps_log = ps_log + open(log_dir + ddl_model + "_corelog_ps" + str(ps_idx) + ".txt", 'r').read().split("\n")

        for w_idx in range(1, num_w + 1):
            rx_dur = []
            tx_dur = []
            first_gpu_op_start = []
            last_gpu_op_end = []
            one_iter_dur = []

            pbtxt_node = pb.import_pbtxt(pbtxt_dir + ddl_model + "/", w_idx)
            ps_cpu_send, ps_cpu_recv, w_cpu_send, w_cpu_recv, w_gpu_send, w_gpu_recv \
                = pb.classify_node(pbtxt_node, num_ps, num_w)

            w_send = {}
            w_send.update(w_cpu_send[w_idx - 1])
            w_send.update(w_gpu_send[w_idx - 1])

            w_recv = {}
            w_recv.update(w_cpu_recv[w_idx - 1])
            w_recv.update(w_gpu_recv[w_idx - 1])

            w_log = open(log_dir + ddl_model + "_corelog_w" + str(w_idx) + ".txt", 'r').read().split("New Step START\n")
            w_log_per_iter = []

            for i in range(WARM_UP + 1, WARM_UP + ITERATIONS + 1):
                w_log_per_iter.append(w_log[i].split("\n"))

            for iter_log in w_log_per_iter:
                send_min_req_start = MAX_VAL
                send_max_req_start = 0
                send_min_resp_start = MAX_VAL
                send_max_resp_start = 0
                send_min_resp_end = MAX_VAL
                send_max_resp_end = 0

                recv_min_req_start = MAX_VAL
                recv_max_req_start = 0
                recv_min_resp_start = MAX_VAL
                recv_max_resp_start = 0
                recv_min_resp_end = MAX_VAL
                recv_max_resp_end = 0

                find_first_gpu_op_start = False

                iter_log.remove("")

                iter_start_time = iter_log[0].split(" ")[1].split(".")
                HMS = list(map(int, iter_start_time[0].split(":")))
                usec = int(iter_start_time[1].split(":")[0])
                iter_start_time_usec = usec + HMS[0] * HOUR * 1000000 + HMS[1] * MINUTE * 1000000 + HMS[2] * 1000000

                iter_end_time = iter_log[len(iter_log)-1].split(" ")[1].split(".")
                HMS = list(map(int, iter_end_time[0].split(":")))
                usec = int(iter_end_time[1].split(":")[0])
                iter_end_time_usec = usec + HMS[0] * HOUR * 1000000 + HMS[1] * MINUTE * 1000000 + HMS[2] * 1000000

                for w_s in iter_log:
                    if "something send" in w_s:
                        key = w_s.split(",")[1] + "," + w_s.split(",")[2]
                        for ps_s in ps_log:
                            if key in ps_s:
                                try:
                                    op_name = w_send[ps_s.split(",")[0].split(" ")[4]]
                                    tensor_name = ps_s.split(",")[0].split(" ")[4]
                                    send_dev = ps_s.split(",")[1]
                                    recv_dev = ps_s.split(",")[2]
                                    send_req_start = int(ps_s.split(",")[8])
                                    send_resp_start = int(ps_s.split(",")[9])
                                    tensor_id = int(ps_s.split(",")[10])
                                    send_resp_end = int(ps_s.split(",")[11])
                                    tensor_bytes = int(ps_s.split(",")[12])

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
                                    pass
                                    # print("error: ", w_s.split(",")[0].split(" ")[4])

                    elif "RecvTensorAsync" in w_s:
                        try:
                            op_name = w_recv[w_s.split(",")[0].split(" ")[4]]
                            tensor_name = w_s.split(",")[0].split(" ")[4]
                            send_dev = w_s.split(",")[1]
                            recv_dev = w_s.split(",")[2]
                            recv_req_start = int(w_s.split(",")[8])
                            recv_resp_start = int(w_s.split(",")[9])
                            tensor_id = int(w_s.split(",")[10])
                            recv_resp_end = int(w_s.split(",")[11])
                            tensor_bytes = int(w_s.split(",")[12])

                            if ("NoOp" not in tensor_name) & ("AssignAdd" not in tensor_name) & ("group_deps" not in tensor_name):
                                if recv_req_start > recv_max_req_start:
                                    recv_max_req_start = recv_req_start
                                if recv_req_start < recv_min_req_start:
                                    recv_min_req_start = recv_req_start
                                if recv_resp_start > recv_max_resp_start:
                                    recv_max_resp_start = recv_resp_start
                                if recv_resp_start < recv_min_resp_start:
                                    recv_min_resp_start = recv_resp_start
                                if recv_resp_end > recv_max_resp_end:
                                    recv_max_resp_end = recv_resp_end
                                if recv_resp_end < recv_min_resp_end:
                                    recv_min_resp_end = recv_resp_end

                        except KeyError:
                            pass
                            # print("error: ", w_s.split(",")[0].split(" ")[4])

                    elif ("Compute op compute start" in w_s) & (find_first_gpu_op_start is False):
                        find_first_gpu_op_start = True
                        first_gpu_op_start_time = int(w_s.split(",")[1])

                    elif "Compute op completed done" in w_s:
                        op_name = w_s.split(",")[3].split(" ")[0]
                        op_cat = w_s.split(",")[3].split(" ")[2].split("[")[0]
                        if ("NoOp" not in op_cat) & ("Const" not in op_cat) & ("Identity" not in op_cat):
                            if ("group_deps" not in op_name) & ("NoOp" not in op_name):
                                last_gpu_op_end_time = int(w_s.split(",")[1])

                rx_dur.append(recv_max_resp_end - recv_min_resp_start)
                tx_dur.append(send_max_resp_end - send_min_resp_start)
                first_gpu_op_start.append(first_gpu_op_start_time)
                last_gpu_op_end.append(last_gpu_op_end_time)
                one_iter_dur.append(iter_end_time_usec - iter_start_time_usec)

            # save results
            # Model
            result[w_idx - 1].append(ddl_model)

            # worker index
            result[w_idx - 1].append(w_idx)

            # RX Duration
            result[w_idx - 1].append((sum(rx_dur)/len(rx_dur))/1000)

            # TX Duration
            result[w_idx - 1].append((sum(tx_dur)/len(tx_dur))/1000)

            # GPU Active
            gpu_active_dur = []
            for i in range(ITERATIONS):
                gpu_active_dur.append(last_gpu_op_end[i] - first_gpu_op_start[i])
            result[w_idx - 1].append((sum(gpu_active_dur)/len(gpu_active_dur))/1000)

            # GPU Idle
            gpu_idle_dur = []
            for i in range(ITERATIONS-1):
                gpu_idle_dur.append(first_gpu_op_start[i+1] - last_gpu_op_end[i])
            result[w_idx - 1].append((sum(gpu_idle_dur) / len(gpu_idle_dur))/1000)

            # GPU 1 Iter time
            result[w_idx - 1].append((sum(one_iter_dur)/len(one_iter_dur))/1000)

            # GPU Total time
            result[w_idx - 1].append(int(open(time_dir + ddl_model + "_w" + str(w_idx) + "_time.txt", 'r').read().split(":")[1]))

            # NVML GPU mem
            nvml_log = open(nvml_dir + ddl_model + "_gpu.txt", 'r').read().split("\n")
            nvml_log.pop(-1)
            gpu_idx = w_gpu_idx[w_idx - 1]
            max_gpu_mem = 0
            for log in nvml_log:
                if log.split(" ")[-14].split(":")[0] is gpu_idx:
                    gpu_mem = int(log.split(" ")[-1])
                    max_gpu_mem = gpu_mem if gpu_mem > max_gpu_mem else max_gpu_mem
            result[w_idx - 1].append(max_gpu_mem/(1024*1024))

            print(result[w_idx - 1])
            print()

    return result



