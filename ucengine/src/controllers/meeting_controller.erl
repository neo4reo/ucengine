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
-module(meeting_controller).

-export([init/0, add/4, list/4, get/4, update/4, leave/4, join/4, roster/4]).

-include("uce.hrl").

init() ->
    [#uce_route{method='POST',
                regexp="/meeting/all",
                callback={?MODULE, add,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"name", required, string},
                           {"start", 0, integer},
                           {"end", ?NEVER_ENDING_MEETING, integer},
                           {"metadata", [], dictionary}]}},

     #uce_route{method='GET',
                regexp="/meeting/([^/]+)",
                callback={?MODULE, list,
                          [{"uid", required, string},
                           {"sid", required, string}]}},


     #uce_route{method='GET',
                regexp="/meeting/all/([^/]+)",
                callback={?MODULE, get,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='PUT',
                regexp="/meeting/all/([^/]+)",
                callback={?MODULE, update,
                          [{"uid", required, string},
                           {"sid", required, string},
                           {"start", 0, integer},
                           {"end", ?NEVER_ENDING_MEETING, integer},
                           {"metadata", [], dictionary}]}},

     #uce_route{method='POST',
                regexp="/meeting/all/([^/]+)/roster",
                callback={?MODULE, join,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='DELETE',
                regexp="/meeting/all/([^/]+)/roster/([^/]+)",
                callback={?MODULE, leave,
                          [{"uid", required, string},
                           {"sid", required, string}]}},

     #uce_route{method='GET',
                regexp="/meeting/all/([^/]+)/roster",
                callback={?MODULE, roster,
                          [{"uid", required, string},
                           {"sid", required, string}]}}].

add(Domain, [], [Uid, Sid, Name, Start, End, Metadata], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, "", "meeting", "add"),
    {ok, created} = uce_meeting:add(Domain,
                                    #uce_meeting{id=Name,
                                                 start_date=Start,
                                                 end_date=End,
                                                 metadata=Metadata}),
    {ok, _} = uce_event:add(Domain, #uce_event{id=none,
                                               from=Uid,
                                               location="",
                                               type="internal.meeting.add"}),
    json_helpers:created(Domain).

list(Domain, [Status], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, "", "meeting", "list"),
    {ok, Meetings} = uce_meeting:list(Domain, Status),
    json_helpers:json(Domain, {array, [meeting_helpers:to_json(Domain, Meeting) || Meeting <- Meetings]}).

get(Domain, [Name], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, "", "meeting", "get"),
    {ok, Meeting} = uce_meeting:get(Domain, Name),
    json_helpers:json(Domain, meeting_helpers:to_json(Domain, Meeting)).

update(Domain, [Name], [Uid, Sid, Start, End, Metadata], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, Name, "meeting", "update"),
    {ok, Meeting} = uce_meeting:get(Domain, Name),
    {ok, updated} = uce_meeting:update(Domain,
                                       #uce_meeting{id=Name,
                                                    start_date=Start,
                                                    end_date=End,
                                                    roster=Meeting#uce_meeting.roster,
                                                    metadata=Metadata}),
    {ok, _} = uce_event:add(Domain, #uce_event{id=none,
                                               from=Uid,
                                               location=Name,
                                               type="internal.meeting.update"}),
    json_helpers:ok(Domain).

join(Domain, [Name], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, Name, "roster", "add"),
    {ok, updated} = uce_meeting:join(Domain, Name, Uid),
    uce_presence:join(Domain, Sid, Name),
    {ok, _} = uce_event:add(Domain,
                            #uce_event{id=none,
                                       type="internal.roster.add",
                                       location=Name,
                                       from=Uid}),
    json_helpers:ok(Domain).

%% TODO : Incomplete Sid must be ToSid
leave(Domain, [Name, User], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, Name, "roster", "delete"),
    {ok, updated} = uce_meeting:leave(Domain, Name, User),
    uce_presence:leave(Domain, Sid, Name),
    {ok, _} = uce_event:add(Domain,
                            #uce_event{id=none,
                                       type="internal.roster.delete",
                                       location=Name,
                                       from=User}),
    json_helpers:ok(Domain).

roster(Domain, [Name], [Uid, Sid], _) ->
    {ok, true} = uce_presence:assert(Domain, Uid, Sid),
    {ok, true} = uce_access:assert(Domain, Uid, Name, "roster", "list"),
    {ok, Roster} = uce_meeting:roster(Domain, Name),
    json_helpers:json(Domain,
                      {array, lists:map(fun(Member) ->
                                                {ok, User} = uce_user:get(Domain, Member),
                                                user_helpers:to_json(Domain, User)
                                        end,
                                        Roster)}).
