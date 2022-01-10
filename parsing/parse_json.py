import json
import parse_pbtxt as pp

HOUR = 3600
MINUTE = 60
WARM_UP = 10
ITERATIONS = 100


def import_json(file):
    with open(file) as f:
        j = json.load(f)
        return j


def node_dur(node_list, n_w, n_ps, ps_send, w_send, ps_recv, w_recv):
    asdf = []
    asaa = []
    for node in node_list:
        try:
            if str(node["args"]["name"]) in ps_recv[0]:
                # print(node["args"]["name"])
                asdf.append(node)
            if str(node["args"]["name"]) in ps_send[0]:
                # print(node["args"]["name"])
                asaa.append(node)
        except KeyError:
            pass




if __name__ == '__main__':

    j = import_json("bench_log/imagenet_resnet101_v2_sync_batch64_w1.json")
    pbtxt = pp.import_pbtxt("bench_log/new_imagenet_resnet101_v2_sync_batch64_w1.pbtxt")
    ps_send, w_send, ps_recv, w_recv = pp.classify_node(pbtxt.node, 2, 2)

    pbtxt = pp.import_pbtxt("bench_log/new_imagenet_resnet101_v2_sync_batch64_w2.pbtxt")
    ps_send, w_send, ps_recv, w_recv = pp.classify_node(pbtxt.node, 2, 2)
    node_dur(j["traceEvents"] , 2, 2, ps_send, w_send, ps_recv, w_recv)




