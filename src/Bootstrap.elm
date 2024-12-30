port module Bootstrap exposing (Flags, main)

import Json.Decode
import Json.Encode


main : Program Flags () msg
main =
    Platform.worker
        { init = \flags -> ( (), dataFromElmToJavascript (main_ flags) )
        , subscriptions = \_ -> Sub.none
        , update = \_ () -> ( (), Cmd.none )
        }


type alias Flags =
    { commit : String
    , env : String
    , version : String
    }


type alias Model =
    { commit : String
    , version : String
    }


cmdGeneratedFolder : String
cmdGeneratedFolder =
    "cmd-generated"


fileName : BuildScript -> String
fileName buildScript =
    case buildScript of
        BuildPortal ->
            "build-portal"

        BuildWebComponents ->
            "build-wc"


type BuildScript
    = BuildPortal
    | BuildWebComponents


port dataFromElmToJavascript : Json.Encode.Value -> Cmd msg


main_ : Flags -> Json.Encode.Value
main_ flags =
    Json.Encode.object
        [ ( "removeFolders"
          , Json.Encode.list Json.Encode.string []
          )
        , ( "addFiles"
          , Json.Encode.object
                [ ( "docs/index.html"
                  , Json.Encode.string topPage
                  )
                , ( "docs/test1/index.html"
                  , Json.Encode.string (viewPage pages.index)
                  )
                , ( "docs/test1/subpage1.html"
                  , Json.Encode.string (viewPage pages.subpage1)
                  )
                , ( "docs/test1/subpage2.html"
                  , Json.Encode.string (viewPage pages.subpage2)
                  )
                , ( "docs/test2/index.html"
                  , Json.Encode.string (viewPage pages.index)
                  )
                , ( "docs/test2/subpage1.html"
                  , Json.Encode.string (viewPage pages.subpage1)
                  )
                , ( "docs/test2/subpage2.html"
                  , Json.Encode.string (viewPage pages.subpage2)
                  )
                ]
          )
        ]


type alias PageMeta =
    { title : String
    , sentence : String
    }


pages :
    { index : PageMeta
    , subpage1 : PageMeta
    , subpage2 : PageMeta
    }
pages =
    { index = { title = "トップページ", sentence = "参照透過性とは、同じ値を与えたら返り値も必ず同じになるような性質である。" }
    , subpage1 = { title = "サブページ1", sentence = "参照透過性を持つことは、その関数が状態を持たないことを保証する。" }
    , subpage2 = { title = "サブページ2", sentence = "状態を持たない数学的な関数は、並列処理を実現するのに適している。" }
    }


topPage : String
topPage =
    """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Top</title>
</head>
<body>
    <ul>
        <li><a href="test1/">test1</a></li>
        <li><a href="test2/">test2</a></li>
    </ul>
</body>
</html>"""


viewPage : PageMeta -> String
viewPage meta =
    """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>""" ++ meta.title ++ """</title>
</head>
<body>
    <header>
        <h1>""" ++ meta.title ++ """</h1>
        <nav>
            <ul>
                <li>""" ++ iif (meta == pages.index) ("<b>" ++ meta.title ++ "</b>") ("<a href='index.html'>" ++ pages.index.title ++ "</a>") ++ """</li>
                <li>""" ++ iif (meta == pages.subpage1) ("<b>" ++ meta.title ++ "</b>") ("<a href='subpage1.html'>" ++ pages.subpage1.title ++ "</a>") ++ """</li>
                <li>""" ++ iif (meta == pages.subpage2) ("<b>" ++ meta.title ++ "</b>") ("<a href='subpage2.html'>" ++ pages.subpage2.title ++ "</a>") ++ """</li>
            </ul>
        </nav>
    </header>
    <main>
        <p>""" ++ meta.sentence ++ """</p>
    </main>
    <hr />
    <footer><a href="..">root</a></footer>
</body>
</html>"""


iif : Bool -> a -> a -> a
iif condition trueCase falseCase =
    if condition then
        trueCase

    else
        falseCase
