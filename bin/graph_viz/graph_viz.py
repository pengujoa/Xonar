# importing networkx
import networkx as nx

# importing matplotlib.pyplot
import matplotlib.pyplot as plt

import tensorflow as tf
from google.protobuf import text_format

from networkx.algorithms.community import asyn_fluidc


def import_pbtxt(file):
    with open(file) as f:
        pbtxt = f.read()
        graph_def = text_format.Parse(pbtxt, tf.compat.v1.GraphDef(), allow_field_number=1)
        return graph_def


def pbtxt_extract_op_node_name(p):
    graph_node_list = []
    # [cyshin] Extracts OPs only running on GPUs
    for node in p.node:
        if "GPU" in node.device:
            graph_node_list.append(node)
    op_node_name_list_in_pbtxt = [node.name for node in graph_node_list]
    # [cyshin] Extracts all OPs
    # op_node_name_list_in_pbtxt = [node.name for node in p.node]
    return op_node_name_list_in_pbtxt


def pbtxt_extract_op_node_edge(p):
    op_node_edge_list_in_pbtxt = []
    graph_node_list = []
    # [cyshin] Extracts OPs only running on GPUs
    for node in p.node:
        if "GPU" in node.device:
            graph_node_list.append(node)
    graph_node_name_list = [node.name for node in graph_node_list]
    # [cyshin] Extracts all OPs
    # graph_node_name_list = [node.name for node in p.node]
    for node in graph_node_list:
        for input in node.input:
            if ":" in input:
                if input[:input.index(":")] in graph_node_name_list:
                    op_node_edge_list_in_pbtxt.append((input[:input.index(":")], node.name)) # , {"dummy_feature":0}))
            elif "^" in input:
                if input[1:] in graph_node_name_list:
                    op_node_edge_list_in_pbtxt.append((input[1:], node.name))  # , {"dummy_feature":0}))
            else:
                if input in graph_node_name_list:
                    op_node_edge_list_in_pbtxt.append((input, node.name))  # , {"dummy_feature":0}))
    return op_node_edge_list_in_pbtxt


def nx_node_form_using_op_node_name(op_list):
    nx_node_form = []
    for op in op_list:
        nx_node_form.append((op, {"comptime":0, "tensorsize":0, "opcoding":0}))
    return nx_node_form


def nx_edge_form_using_op_node_edge(edge_list):
    # 같은 흐름으로 코딩하려고 만들어놓음
    return edge_list


def build_nx_graph(pbtxt_path, json_path, DNN_model):

    pbtxt_data = import_pbtxt(pbtxt_path)
    # json_data = import_json(json_path + "CNN/" + DNN_model + ".json")

    op_node_name = pbtxt_extract_op_node_name(pbtxt_data)
    op_node_edge = pbtxt_extract_op_node_edge(pbtxt_data)

    # print(op_node_name)
    # print(op_node_edge)

    nx_node_form = nx_node_form_using_op_node_name(op_node_name)
    nx_edge_form = nx_edge_form_using_op_node_edge(op_node_edge)

    # G = nx.MultiDiGraph()
    G = nx.MultiGraph()
    G.add_nodes_from(nx_node_form)
    G.add_edges_from(nx_edge_form)

    # add_feature_from_pbtxt(G, pbtxt_data)
    # add_feature_from_json(G, json_data)
    # add_feature_from_csv(G, pbtxt_data)

    return G


def node_name_split(node_name_list):
    split_node_name_list = []

    for node_name in node_name_list:
        try:
            # print(node_name.split("/"))
            split_node_name_list.append(node_name.split("/"))
        except KeyError:
            pass

    return split_node_name_list


def new_node_grouping(G, num_of_group):
    grouped_node_name_list = []
    grouped_node_idx = {}
    group_num = 0

    for i, community in enumerate(asyn_fluidc(G, k=num_of_group, seed=42)):
        # print("community_{:0>2d}: {}".format(i, community))
        grouped_node_name_list.append(list(community))
        for node_name in list(community):
            grouped_node_idx[node_name] = group_num
        group_num += 1

    return grouped_node_name_list, grouped_node_idx


def group_nx_graph(G, num_of_group):
    # Grouped_G = nx.DiGraph()
    Grouped_G = nx.Graph()
    op_node_name = list(G.nodes)
    split_op_node_name = node_name_split(op_node_name)

    # grouped_op_node_name, op_node_group_num = grouping.node_grouping(op_node_name, split_op_node_name)
    grouped_op_node_name, op_node_group_num = new_node_grouping(G, num_of_group)
    # for i in range(len(grouped_op_node_name)):
    #     print(grouped_op_node_name[i])


    for group_num, group in enumerate(grouped_op_node_name):
        sub_G = nx.Graph()
        comptime_value = 0
        tensorsize_value = 0
        opcoding_value = 0 #yks
        for op_node_name in group:
            node = [(op_node_name, G.nodes[op_node_name])]
            sub_G.add_nodes_from(node)
            comptime_value += int(G.nodes[op_node_name]['comptime'])
            tensorsize_value += int(G.nodes[op_node_name]['tensorsize'])
            opcoding_value += float(G.nodes[op_node_name]['opcoding'])
            #rint(opcoding_value)

        Grouped_G.add_node(group_num, comptime=comptime_value, tensorsize=tensorsize_value, opcount=len(group), opcoding=opcoding_value, nodesinfo=sub_G)

    # flat_op_node_group_num = list(itertools.chain(*op_node_group_num))


    op_edge_list = list(G.edges)
    for edge in op_edge_list:
        Grouped_G.add_edge(op_node_group_num[edge[0]], op_node_group_num[edge[1]])

    # Grouped_G.add_edges_from(nx_edge_form)

    return Grouped_G


def draw_nx_graph(g):
    nx.draw_networkx(g)
    plt.savefig("filename.png")


if __name__ == '__main__':
    G = build_nx_graph("v100PS2W2_imagenet_vgg16_async_batch32_w1.pbtxt", "v100PS2W2_imagenet_vgg16_async_batch32_w1.pbtxt", "dummy")
    i_n = G.number_of_nodes()
    i_e = G.number_of_edges()
    # remove singletons
    G.remove_nodes_from(list(nx.isolates(G)))
    a_n = G.number_of_nodes()
    a_e = G.number_of_edges()
    # choose largest subgraph
    if nx.number_connected_components(G) > 1:
        G = G.subgraph(max(nx.connected_components(G), key=len)).copy()
    b_n = G.number_of_nodes()
    b_e = G.number_of_edges()

    G_G = group_nx_graph(G, 100)
    c_n = G_G.number_of_nodes()
    c_e = G_G.number_of_edges()

    # remove selfloop
    G_G.remove_edges_from(nx.selfloop_edges(G_G))
    d_n = G_G.number_of_nodes()
    d_e = G_G.number_of_edges()

    draw_nx_graph(G_G)
