module Picasso.Input exposing (input, inputWithTitle)

{-| A module that provides basic input elements


# Constructors

@docs input, inputWithTitle

-}

import Html exposing (Html, div, text)
import Html.Attributes exposing (class)


base : List (Html.Attribute msg)
base =
    [ class "bg-white"
    , class "focus:outline-none"
    , class "focus:shadow-outline"
    , class "border-2 border-gray-300"
    , class "rounded-lg"
    , class "px-4 py-2"
    , class "appearance-none"
    , class "font-archivo"
    ]


{-| Builds a new input box with based styling combined with arguments
-}
input : List (Html.Attribute msg) -> List (Html msg) -> Html msg
input attrs html =
    Html.input (base ++ attrs) html


title : String -> Html msg
title withContents =
    div
        [ class "text-gray-500"
        , class "font-archivo"
        ]
        [ text withContents ]


{-| Builds a new input box with based styling combined with arguments preceded with a title text
-}
inputWithTitle : String -> List (Html.Attribute msg) -> List (Html msg) -> Html msg
inputWithTitle withContents attrs html =
    div
        [ class "flex"
        , class "flex-col"
        ]
        [ title withContents
        , input (class "mt-2" :: attrs) html
        ]
