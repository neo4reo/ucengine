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
-module(uce_meeting).

-author('victor.goya@af83.com').

-export([add/2,
         delete/2,
         update/2,
         get/2,
         list/2,
         join/3,
         leave/3,
         roster/2,
         exists/2]).

-include("uce.hrl").


add(Domain, #uce_meeting{id=Id} = Meeting) ->
    case exists(Domain, Id) of
        true ->
            throw({error, conflict});
        false ->
            (db:get(?MODULE, Domain)):add(Domain, Meeting)
    end.

delete(Domain, Id) ->
    case exists(Domain, Id) of
        false ->
            throw({error, not_found});
        true ->
            (db:get(?MODULE, Domain)):delete(Domain, Id)
    end.

get(Domain, Id) ->
    (db:get(?MODULE, Domain)):get(Domain, Id).

update(Domain, #uce_meeting{id=Id} = Meeting) ->
    case exists(Domain, Id) of
        false ->
            throw({error, not_found});
        true ->
            (db:get(?MODULE, Domain)):update(Domain, Meeting)
    end.

list(Domain, Status) ->
    {ok, Meetings} = (db:get(?MODULE, Domain)):list(Domain),
    if
        Status == "all";
        Status == "upcoming";
        Status == "opened";
        Status == "closed" ->
            Now = utils:now(),
            FilteredMeetings =
                lists:filter(fun(#uce_meeting{start_date=Start, end_date=End}) ->
                                     case Status of
                                         "all" ->
                                             true;
                                         "upcoming" ->
                                             Now < Start;
                                         "opened" ->
                                             case Now >= Start of
                                                 true ->
                                                     if
                                                         End == ?NEVER_ENDING_MEETING ->
                                                             true;
                                                         Now =< End ->
                                                             true;
                                                         true ->
                                                             false
                                                     end;
                                                 false ->
                                                     false
                                             end;
                                         "closed" ->
                                             if
                                                 End == ?NEVER_ENDING_MEETING ->
                                                     false;
                                                 Now >= End ->
                                                     true;
                                                 true ->
                                                     false
                                             end;
                                         _ ->
                                             false
                                     end
                             end,
                             Meetings),
            {ok, FilteredMeetings};
        true ->
            throw({error, bad_parameters})
    end.

exists(_Domain, "") ->
    true; % root
exists(Domain, Id) ->
    case catch get(Domain, Id) of
        {error, not_found} ->
            false;
        {error, Reason} ->
            throw({error, Reason});
        {ok, _} ->
            true
    end.

join(Domain, Id, User) ->
    case uce_user:exists(Domain, User) of
        false ->
            throw({error, not_found});
        true ->
            {ok, Meeting} = get(Domain, Id),
            case lists:member(User, Meeting#uce_meeting.roster) of
                false ->
                    update(Domain, Meeting#uce_meeting{roster=Meeting#uce_meeting.roster ++ [User]});
                true ->
                    {ok, updated}
            end
    end.

leave(Domain, Id, User) ->
    case uce_user:exists(Domain, User) of
        false ->
            throw({error, not_found});
        true ->
            {ok, Meeting} = get(Domain, Id),
            case lists:member(User, Meeting#uce_meeting.roster) of
                false ->
                    throw({error, not_found});
                true ->
                    Roster = lists:subtract(Meeting#uce_meeting.roster, [User]),
                    update(Domain, Meeting#uce_meeting{roster=Roster})
            end
    end.

roster(Domain, Id) ->
    {ok, Meeting} = get(Domain, Id),
    {ok, Meeting#uce_meeting.roster}.

