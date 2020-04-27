module Page.Question exposing
    ( Message
    , Model
    , init
    , subscriptions
    , update
    , view
    , viewIndex
    )

import Api.Questions exposing (QuestionDiscriminator, ServerQuestion)
import Cmd exposing (withCmd, withNoCmd)
import Html exposing (Html, div)
import Html.Attributes exposing (class)
import Html.Events as Html
import Session exposing (Viewer)
import Task
import Task.Extra



-- MODEL


type QuestionState
    = Existing
    | Deleted


type alias Model =
    { viewer : Viewer
    , question : Maybe ServerQuestion
    , state : QuestionState
    }


init : Viewer -> { d | idPoll : Int, idQuestion : Int } -> ( Model, Cmd Message )
init viewer discriminator =
    { viewer = viewer
    , question = Nothing
    , state = Existing
    }
        |> withCmd [ Cmd.succeed <| NowRequestQuestion <| QuestionDiscriminator discriminator.idPoll discriminator.idQuestion ]



-- UPDATE


type Message
    = NowRequestQuestion QuestionDiscriminator
    | NowDeleteQuestion QuestionDiscriminator
    | GotQuestion (Maybe ServerQuestion)
    | GotDeletedQuestion
    | GotInvalidCredentials
    | GotError


update : Message -> Model -> ( Model, Cmd Message )
update msg model =
    case msg of
        NowRequestQuestion questionDiscriminator ->
            let
                viewer =
                    Session.viewerCredentials model.viewer
            in
            model
                |> withCmd
                    [ Api.Questions.getQuestion viewer questionDiscriminator Just
                        |> Task.map GotQuestion
                        |> Task.mapError
                            (\error ->
                                case error of
                                    Api.Questions.GotBadCredentials ->
                                        GotInvalidCredentials

                                    _ ->
                                        GotQuestion Nothing
                            )
                        |> Task.Extra.execute
                    ]

        NowDeleteQuestion questionDiscriminator ->
            let
                viewer =
                    Session.viewerCredentials model.viewer
            in
            model
                |> withCmd
                    [ Api.Questions.delete viewer questionDiscriminator GotDeletedQuestion
                        |> Task.mapError
                            (\error ->
                                case error of
                                    Api.Questions.GotBadCredentials ->
                                        GotInvalidCredentials

                                    _ ->
                                        GotError
                            )
                        |> Task.Extra.execute
                    ]

        GotQuestion serverQuestion ->
            { model | question = serverQuestion }
                |> withNoCmd

        GotDeletedQuestion ->
            { model | question = Nothing }
                |> withNoCmd

        GotInvalidCredentials ->
            { model | question = Nothing }
                |> withNoCmd

        GotError ->
            { model | question = Nothing }
                |> withNoCmd


subscriptions : Sub Message
subscriptions =
    Sub.none



-- VIEW


view : Model -> Html Message
view model =
    case model.question of
        Just question ->
            Html.tr
                [ class " border-b active:shadow-inner hover:bg-gray-100"
                ]
                [ Html.td
                    [ class "py-3 px-4"
                    , class "font-bold font-archivo break-all"
                    ]
                    [ Html.text question.title ]
                , Html.td
                    [ class "py-2" ]
                    [ Html.text <| visibility question ]
                , Html.td
                    [ class "text-right px-8" ]
                    [ Html.button
                        [ class "text-gray-500 hover:text-red-500 "
                        , class "capitalize font-archivo"
                        ]
                        [ Html.text "Delete" ]
                    ]
                ]

        Nothing ->
            Html.tr
                [ class " border-b active:shadow-inner hover:bg-gray-100"
                ]
                [ Html.td
                    []
                    []
                , Html.td
                    []
                    []
                , Html.td
                    []
                    []
                ]


visibility : ServerQuestion -> String
visibility question =
    case question.visibility of
        Api.Questions.Visible ->
            "Visible"

        Api.Questions.Hidden ->
            "Hidden"

        Api.Questions.Archived ->
            "Archived"


viewIndex : Model -> Float
viewIndex _ =
    0