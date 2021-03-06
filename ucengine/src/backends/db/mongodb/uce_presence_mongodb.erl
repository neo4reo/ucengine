%%
%%  U.C.Engine - Unified Colloboration Engine
%%  Copyright (C) 2011 af83
%%
%%  This program is free software: you can redistribute it and/or modify
%%  it under the terms of the GNU Affero General Public License as published by
%%  the Free Software Foundation, either version 3 of the License, or
%%  (at your option) any later version.
%%
%%  This program is distributed in the hope that it will be useful,
%%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%%  GNU Affero General Public License for more details.
%%
%%  You should have received a copy of the GNU Affero General Public License
%%  along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
-module(uce_presence_mongodb).

-author('victor.goya@af83.com').

-behaviour(gen_uce_presence).

-export([add/2,
         get/2,
         delete/2,
         update/2,
         all/1,
         index/1]).

-include("uce.hrl").
-include("mongodb.hrl").


%%--------------------------------------------------------------------
%% @spec (Domain, #uce_presence{}) -> {ok, Id}
%% @doc Insert given record #uce_presence{} in uce_presence mongodb table
%% @end
%%--------------------------------------------------------------------
add(Domain, #uce_presence{id=Id} = Presence) ->
    mongodb_helpers:ok(emongo:insert_sync(Domain, "uce_presence", to_collection(Domain, Presence))),
    {ok, Id}.

%%--------------------------------------------------------------------
%% @spec (Domain::list) -> {ok, [#uce_presence{}, #uce_presence{}, ..] = Presences::list} | {error, bad_parameters}
%% @doc List all record #uce_presence for the given domain
%% @end
%%--------------------------------------------------------------------
all(Domain) ->
    Collections = emongo:find_all(Domain, "uce_presence", [{"domain", Domain}]),
    Presences = lists:map(fun(Collection) ->
                                  from_collection(Collection)
                          end,
                          Collections),
    {ok, Presences}.

%%--------------------------------------------------------------------
%% @spec (Domain::list, Sid::list) -> {ok, #uce_presence{}} | {error, bad_parameters} | {error, not_found}
%% @doc Get record uce_presence which correspond to the given id and domain
%% @end
%%--------------------------------------------------------------------
get(Domain, SId) ->
    case emongo:find_one(Domain, "uce_presence", [{"id", SId}, {"domain", Domain}]) of
        [Collection] ->
            {ok, from_collection(Collection)};
        [] ->
            throw({error, not_found})
    end.

%%--------------------------------------------------------------------
%% @spec (Domain::list, Sid::list) -> {ok, deleted}
%% @doc Delete record
%% @end
%%--------------------------------------------------------------------
delete(Domain, Sid) ->
    mongodb_helpers:ok(emongo:delete_sync(Domain, "uce_presence", [{"id", Sid}, {"domain", Domain}])),
    {ok, deleted}.

%%--------------------------------------------------------------------
%% @spec (Domain::list, #uce_presence{}) -> {ok, updated}
%% @doc Update record
%% @end
%%--------------------------------------------------------------------
update(Domain, #uce_presence{id=Id}=Presence) ->
    mongodb_helpers:updated(emongo:update_sync(Domain, "uce_presence",
                                               [{"id", Id}, {"domain", Domain}],
                                               to_collection(Domain, Presence), false)),
    {ok, udpated}.


%%--------------------------------------------------------------------
%% @spec ([{Key::list, Value::list}, {Key::list, Value::list}, ...] = Collection::list) -> #uce_presence{} | {error, bad_parameters}
%% @doc Convert collection returned by mongodb to valid record #uce_meeting{}
%% @end
%%--------------------------------------------------------------------
from_collection(Collection) ->
    case utils:get(mongodb_helpers:collection_to_list(Collection),
                   ["id", "domain", "user", "auth", "last_activity", "timeout", "meetings", "metadata"]) of
        [Id, _Domain, User, Auth, LastActivity, Timeout, Meetings, Metadata] ->
            #uce_presence{id=Id,
                          user=User,
                          auth=Auth,
                          last_activity=list_to_integer(LastActivity),
                          timeout=list_to_integer(Timeout),
                          meetings=Meetings,
                          metadata=Metadata};
        _ ->
            throw({error, bad_parameters})
    end.

%%--------------------------------------------------------------------
%% @spec (#uce_presence{}) -> [{Key::list, Value::list}, {Key::list, Value::list}, ...] = Collection::list
%% @doc Convert #uce_presence{} record to valid collection
%% @end
%%--------------------------------------------------------------------
to_collection(Domain, #uce_presence{id=Id,
                                    user=User,
                                    auth=Auth,
                                    last_activity=LastActivity,
                                    timeout=Timeout,
                                    meetings=Meetings,
                                    metadata=Metadata}) ->
    [{"id", Id},
     {"domain", Domain},
     {"user", User},
     {"auth", Auth},
     {"last_activity", integer_to_list(LastActivity)},
     {"timeout", integer_to_list(Timeout)},
     {"meetings", Meetings},
     {"metadata", Metadata}].

%%--------------------------------------------------------------------
%% @spec (Domain::list) -> ok::atom
%% @doc Create index for uce_presence collection in database 
%% @end
%%--------------------------------------------------------------------
index(Domain) ->
    Indexes = [{"id", 1}, {"domain", 1}],
    emongo:ensure_index(Domain, "uce_presence", Indexes),
    ok.
