from sample import greet


def test_greet():
    assert greet() == "hello, world"
    assert greet("Asha") == "hello, Asha"
