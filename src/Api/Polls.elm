module Api.Polls exposing
    ( ServerPoll, ClientPoll, PollDiscriminator, PollError(..)
    , getPollList, getPoll, delete, create, update
    , urlParser
    )

{-| A module that provides ways to manipulate and to communicate with the
backend about everything polls


# Types

@docs ServerPoll, ClientPoll, PollDiscriminator, PollError


# Endpoints

@docs getPollList, getPoll, delete, create, update


# urlParser

@docs urlParser

-}

import Api exposing (Credentials, get)
import Http
import Json.Decode exposing (Decoder, field)
import Json.Encode
import Task exposing (Task)
import Url.Parser exposing (int)


type PollError
    = GotNotFound
    | GotBadCredentials
    | GotBadNetwork


type alias ServerPoll =
    { idModerator : Int
    , idPoll : Int
    , title : String
    }


type alias ClientPoll =
    String


type alias PollDiscriminator =
    Int


{-| A command that will try to request the list of polls existing for a logged
in moderator, and tell what
the issue was if it did not work.
-}
getPollList : Credentials -> (List ServerPoll -> a) -> Task PollError a
getPollList credentials transform =
    let
        endpoint =
            anyPoll credentials
    in
    get
        { body =
            Json.Encode.null
        , endpoint = endpoint
        , decoder = pollListDecoder
        }
        |> Task.mapError
            (\error ->
                case error of
                    Http.BadStatus 404 ->
                        GotNotFound

                    Http.BadStatus 403 ->
                        GotBadCredentials

                    _ ->
                        GotBadNetwork
            )
        |> Task.map transform


{-| A command that will try to request a specific poll existing for a logged
in moderator, and tell what the issue was if it did not work.
-}
getPoll : Credentials -> PollDiscriminator -> (ServerPoll -> a) -> Task PollError a
getPoll credentials pollDiscriminator transform =
    let
        endpoint =
            somePoll pollDiscriminator credentials
    in
    Api.get
        { body =
            Json.Encode.null
        , endpoint = endpoint
        , decoder = pollDecoder
        }
        |> Task.mapError
            (\error ->
                case error of
                    Http.BadStatus 403 ->
                        GotBadCredentials

                    _ ->
                        GotBadNetwork
            )
        |> Task.map transform


{-| Deletes a provided poll from the backend, and returns the specified value on success.
-}
delete : Credentials -> PollDiscriminator -> a -> Task PollError a
delete credentials pollDiscriminator return =
    let
        endpoint =
            somePoll pollDiscriminator credentials
    in
    Api.delete
        { body = Json.Encode.null
        , endpoint = endpoint
        , decoder = Json.Decode.succeed return
        }
        |> Task.mapError
            (\error ->
                case error of
                    Http.BadStatus 404 ->
                        GotNotFound

                    Http.BadStatus 403 ->
                        GotBadCredentials

                    _ ->
                        GotBadNetwork
            )


{-| Create a poll with a specified title, and returns the created poll on success
-}
create : Credentials -> ClientPoll -> (ServerPoll -> a) -> Task PollError a
create credentials clientPoll transform =
    let
        endpoint =
            anyPoll credentials
    in
    Api.post
        { body =
            Json.Encode.object
                [ ( "title", Json.Encode.string clientPoll ) ]
        , endpoint = endpoint
        , decoder = pollDecoder
        }
        |> Task.mapError
            (\error ->
                case error of
                    Http.BadStatus 403 ->
                        GotBadCredentials

                    _ ->
                        GotBadNetwork
            )
        |> Task.map transform


{-| Updates a poll with a specified title, and returns the created poll on success
-}
update : Credentials -> PollDiscriminator -> ClientPoll -> (ServerPoll -> a) -> Task PollError a
update credentials pollDiscriminator clientPoll transform =
    let
        endpoint =
            somePoll pollDiscriminator credentials
    in
    Api.put
        { body =
            Json.Encode.object
                [ ( "title", Json.Encode.string clientPoll ) ]
        , endpoint = endpoint
        , decoder = pollDecoder
        }
        |> Task.mapError
            (\error ->
                case error of
                    Http.BadStatus 403 ->
                        GotBadCredentials

                    _ ->
                        GotBadNetwork
            )
        |> Task.map transform


anyPoll : Credentials -> Api.Endpoint
anyPoll credentials =
    Api.authenticated credentials
        |> Api.withPath "mod/"
        |> Api.withPath (String.fromInt (Api.moderatorId credentials))
        |> Api.withPath "/poll"


somePoll : PollDiscriminator -> Credentials -> Api.Endpoint
somePoll pollDiscriminator credentials =
    anyPoll credentials
        |> Api.withPath ("/" ++ String.fromInt pollDiscriminator)


pollDecoder : Decoder ServerPoll
pollDecoder =
    Json.Decode.map3 ServerPoll
        (field "idModerator" Json.Decode.int)
        (field "idPoll" Json.Decode.int)
        (field "title" Json.Decode.string)


pollListDecoder : Decoder (List ServerPoll)
pollListDecoder =
    Json.Decode.list <|
        pollDecoder


urlParser : Url.Parser.Parser (PollDiscriminator -> a) a
urlParser =
    int
