-module(acc_test_helper).
-compile(export_all).
-author("bartek").


test_save_acc(#{type := <<"chat">>} = Acc, _State) ->
    random:seed(erlang:phash2([node()]),
                erlang:monotonic_time(),
                erlang:unique_integer()),
    Rand = random:uniform(),
    Acc1 = mongoose_acc:add_prop(random_prop, Rand, Acc),
    Acc2 = mongoose_acc:put(should_be_stripped, 123, Acc1),
    Data = {mongoose_acc:get(ref, Acc2), mongoose_acc:get(timestamp, Acc2), Rand},
    ets:insert(test_message_index, Data),
    Acc2;
test_save_acc(Acc, _State) -> Acc.

test_check_acc({F, T, #{type := <<"chat">>} = Acc, P}) ->
    try
        check_acc(Acc),
        {F, T, Acc, P}
    catch error:{badmatch, _} ->
        drop
    end;
test_check_acc(Arg) ->
    Arg.

test_check_final_acc(#{type := <<"chat">>} = Acc, _Jid, _From, _To, _El) ->
    try
        check_acc(Acc, stripped),
        Acc
    catch error:{badmatch, _} ->
        drop
    end;
test_check_final_acc(Acc, _Jid, _From, _To, _El) ->
    Acc.

recreate_table() ->
    try ets:delete(test_message_index) catch _:_ -> ok end,
    ets:new(test_message_index, [named_table, public, {heir, whereis(ejabberd_c2s_sup), none}]).

check_acc(#{type := <<"chat">>} = Acc) ->
    Ref = mongoose_acc:get(ref, Acc),
    [Data] = ets:lookup(test_message_index, Ref),
    Data = {Ref, mongoose_acc:get(timestamp, Acc), mongoose_acc:get_prop(random_prop, Acc)};
check_acc(_Acc) -> ok.

check_acc(Acc, stripped) ->
    undefined = mongoose_acc:get(should_be_stripped, Acc, undefined),
    check_acc(Acc).

