-module(ring).
-export([create/1,createHead/1,createTail/1
  , rpc/4
]).

% Remote Procedure Call
rpc(To, Msg, Timeout, Alt) ->
  To ! {self(), Msg},
  receive
    {To, Val} -> Val
  after Timeout -> Alt
  end.
% rpc(Ring, {emit, M}, 5000, timeout)

% リングを作る
create(N) ->
    Head = spawn(ring, createHead, [N]),
    io:format("register~n"),
    register(head, Head),
    Head.

createHead(1) ->
    io:format("~p (head) ready N is fix1~n", [self()]),
    loopHead(self());
createHead(N) ->
    io:format("~p (head) ready N is ~p~n", [self(), N]),
    loopHead(spawn(ring, createTail, [N - 1])).

loopHead(Next) ->
    receive
        {Client, {emit, M}} ->
            io:format("~p emit! Client=~p M=~p Next=~p~n", [self(), Client, M, Next]),
            Next ! {self(), {relay, Client, M, 1}},
            loopHead(Next);
        {_From, {relay, Client, M=1, Passed}} ->
            io:format("~p reached! Client=~p M=~p Next=~p~n", [self(), Client, M, Next]),
            Client ! {self(), {reached, Passed}},
            loopHead(Next);
        {_From, {relay, Client, M, Passed}} ->
            io:format("~p loop! M=~p Next=~p~n", [self(), M, Next]),
            Next ! {self(), {relay, Client, M - 1, Passed + 1}},
            loopHead(Next)
    end.

createTail(1) ->
    io:format("~p (last) ready N is fix1, head is ~p~n", [self(), whereis(head)]),
    loopTail(whereis(head));
createTail(N) ->
    io:format("~p (tail) ready N is ~p~n", [self(), N]),
    loopTail(spawn(ring, createTail, [N - 1])).

loopTail(Next) ->
    receive
        {_From, {relay, Client, M, Passed}} ->
            io:format("~p ralay! M=~p Next=~p~n", [self(), M, Next]),
            Next ! {self(), {relay, Client, M, Passed + 1}},
            loopTail(Next)
    end.

