module Page.BadCredentials exposing
    ( Model, Message
    , update, view
    , init, toSession
    )

{-| A page module that displays a message when a user's credentials are not valid anymore


# TEA

@docs Model, Message
@docs update, view


# functions

@docs init, toSession

-}

import Cmd.Extra exposing (withCmds)
import Html exposing (Html, br, div, text)
import Html.Attributes exposing (class)
import Process
import Route
import Session exposing (Session)
import Task
import Task.Extra


type alias Model =
    Session


type Message
    = Redirect


{-| Returns the session of the page
-}
toSession : Model -> Session
toSession =
    identity


init : Session -> ( Model, Cmd Message )
init session =
    session
        |> withCmds
            [ Process.sleep (85 * 100)
                |> Task.andThen (\_ -> Task.succeed Redirect)
                |> Task.Extra.execute
            ]


update : Message -> Model -> ( Model, Cmd Message )
update message session =
    case message of
        Redirect ->
            session
                |> withCmds
                    [ Route.replaceUrl
                        (Session.sessionNavKey session)
                        Route.Logout
                    ]


view : Model -> List (Html Message)
view _ =
    [ div
        [ class "m-auto max-w-lg bg-white px-8 py-4 my-8 shadow-xl rounded-lg"
        , class "font-archivo font-semibold text-3xl"
        ]
        [ text "Gosh, your login info is not valid anymore ⏳"
        , br [] []
        , br [] []
        , text "Going back Home 🚀"
        ]
    ]
