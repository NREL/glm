# -*- coding: utf-8 -*-
import pytest
import glm
import json
import pytest as pt
import os


def test_4node():

    l1 = glm.load("./tests/data/4node.glm")
    l2 = glm.load("./tests/data/powerflow_IEEE_4node.glm")

    assert l1 == json.load(open("./tests/data/4node.json"))
    assert l2 == json.load(open("./tests/data/powerflow_IEEE_4node.json"))

    with open("./tests/data/4node.glm") as f:
        l1 = glm.load(f)
        assert l1 == json.load(open("./tests/data/4node.json"))

    with open("./tests/data/powerflow_IEEE_4node.glm") as f:
        l2 = glm.load(f)
        assert l2 == json.load(open("./tests/data/powerflow_IEEE_4node.json"))


def test_nested():
    len(glm.load("./tests/data/configuration.glm")) == 7


def test_schedules():

    l1 = glm.load("./tests/data/appliance_schedules.glm")
    l2 = glm.load("./tests/data/schedule1.glm")

    assert l1 == json.load(open("./tests/data/appliance_schedules.json"))
    assert l2 == json.load(open("./tests/data/schedule1.json"))


def test_error():
    with pt.raises(Exception):
        # needs semicolon in timezone line
        _ = glm.loads(
            """
                        clock {
                                timestamp '2000-01-01 0:00:00';
                                timezone EST+5EDT
                                }
        """
        )


def test_warning():
    # TODO: raise python warnings
    _ = glm.loads(
        """
               clock {
                       timestamp '2000-01-01 0:00:00';
                       timezone EST+5EDT;
                       };

               #define stylesheet=gridlab-d.svn.sourceforge.net/viewvc/gridlab-d/trunk/core/gridlabd-2_0
    """
    )


def test_IEEE_13_glm():

    l1 = glm.load("./tests/data/IEEE-13.glm")
    l2 = glm.load("./tests/data/IEEE_13_Node_Test_Feeder.glm")
    l3 = glm.load("./tests/data/IEEE_13_Node_With_Houses.glm")

    assert l1 == json.load(open("./tests/data/IEEE-13.json"))
    assert l2 == json.load(open("./tests/data/IEEE_13_Node_Test_Feeder.json"))
    assert l3 == json.load(open("./tests/data/IEEE_13_Node_With_Houses.json"))


def test_powerflow_IEEE_4node_json():

    l1 = json.load(open("./tests/data/powerflow_IEEE_4node.json"))

    with open("./tests/data/tmp", "w") as f:
        glm.dump(l1, f)
    assert open("./tests/data/tmp").read() == open("./tests/data/powerflow_IEEE_4node.glm").read()

    glm.dump(l1, "./tests/data/tmp")
    assert open("./tests/data/tmp").read() == open("./tests/data/powerflow_IEEE_4node.glm").read()
    os.remove("./tests/data/tmp")


def test_powerflow_nested():

    l1 = json.load(open("./tests/data/131_super_node_case_gridlabd_model.json"))

    assert glm.dumps(l1) == open("./tests/data/131_super_node_case_gridlabd_model.glm").read()


def test_taxonomy_feeder_R1_12_47_1():

    l1 = glm.load("./tests/data/taxonomy_feeder_R1-12.47-1.glm")

    assert l1 == json.load(open("./tests/data/taxonomy_feeder_R1-12.47-1.json"))
