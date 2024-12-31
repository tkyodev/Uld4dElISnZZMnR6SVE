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
          , ((( "docs/index.html"
              , topPage
              )
                :: (pages
                        |> site
                            { path = "site1"
                            , snippetTop = ""
                            , snippetBottom = ""
                            }
                   )
                ++ (pages
                        |> site
                            { path = "site2"
                            , snippetTop = extraCanonical srcPreCanonical
                            , snippetBottom = ""
                            }
                   )
                ++ (pages
                        |> site
                            { path = "site3"
                            , snippetTop = extraEarlyAccess srcLocalEarlyAccess
                            , snippetBottom = ""
                            }
                   )
             )
                |> List.map (Tuple.mapSecond Json.Encode.string)
            )
                |> Json.Encode.object
          )
        ]


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
        <li><a href="site1/index.html">site1</a></li>
        <li><a href="site2/index.html">site2</a> """ ++ srcPreCanonical ++ """</li>
        <li><a href="site3/index.html">site3</a> """ ++ srcLocalEarlyAccess ++ """</li>
    </ul>
</body>
</html>"""


srcLocalEarlyAccess : String
srcLocalEarlyAccess =
    "http://127.0.0.1:8080/otft-early-access.min.js"


srcPreCanonical : String
srcPreCanonical =
    "https://membership.rakuten-static.com/pre/ml/web-components.min.js"


site :
    { path : String
    , snippetTop : String
    , snippetBottom : String
    }
    -> Pages
    -> List ( String, String )
site { path, snippetTop, snippetBottom } pages_ =
    [ ( "docs/" ++ path ++ "/index.html"
      , viewPage
            { projectName = path
            , snippetTop = snippetTop
            , snippetBottom = snippetBottom
            , meta = pages_.index
            }
      )
    , ( "docs/" ++ path ++ "/subpage1.html"
      , viewPage
            { projectName = path
            , snippetTop = snippetTop
            , snippetBottom = snippetBottom
            , meta = pages_.subpage1
            }
      )
    , ( "docs/" ++ path ++ "/subpage2.html"
      , viewPage
            { projectName = path
            , snippetTop = snippetTop
            , snippetBottom = snippetBottom
            , meta = pages_.subpage2
            }
      )
    ]


type alias PageMeta =
    { title : String
    , sentence : String
    }


type alias Pages =
    { index : PageMeta
    , subpage1 : PageMeta
    , subpage2 : PageMeta
    }


pages : Pages
pages =
    { index = { title = "トップページ", sentence = "参照透過性とは、同じ値を与えたら返り値も必ず同じになるような性質である。" }
    , subpage1 = { title = "サブページ1", sentence = "参照透過性を持つことは、その関数が状態を持たないことを保証する。" }
    , subpage2 = { title = "サブページ2", sentence = "状態を持たない数学的な関数は、並列処理を実現するのに適している。" }
    }


extraCanonical : String -> String
extraCanonical src =
    "<script src='" ++ src ++ """' async></script>
<r10-language-selector
    selected-theme="light"
    debug="true"
    otft-api-url="https://translate-pa.googleapis.com/v1/translateHtml"
    otft-content-type="application/json+protobuf"
    otft-key-name="x-goog-api-key"
    otft-key-value="VeBRlQYFma2pXUMRFRIVUUiNGcxBTSoVGM2dFRI12T1IDMBlkehN"
    otft-max-number-of-text-nodes="8"
    otft-path='"*"'
    otft-payload='[[[{{data}}],"{{source}}","{{target}}"],"te_lib"]'
    otft-cache-id="abc123"
    otft-cache-ttl="3600"
    style="
        position: fixed;
        top: 10px;
        right: 10px;
    ">
</r10-language-selector> """


extraEarlyAccess : String -> String
extraEarlyAccess src =
    -- http://127.0.0.1:8080/otft-early-access.min.js
    "<script src='" ++ src ++ """'></script>
<script>
    __otft_earlyAccess(
        { primaryColor: 'blue'
        , borderRadius: '5'
        , withDisclaimer: 'false'
        , debug: 'true'
        , otftApiUrl: 'https://translate-pa.googleapis.com/v1/translateHtml'
        , otftContentType: 'application/json+protobuf'
        , otftKeyName: 'x-goog-api-key'
        , otftKeyValue: 'VeBRlQYFma2pXUMRFRIVUUiNGcxBTSoVGM2dFRI12T1IDMBlkehN'
        , otftMaxNumberOfTextNodes: '8'
        , otftPath: '"*"'
        , otftPayload:  '[[[{{data}}],"{{source}}","{{target}}"],"te_lib"]'
        , otftCacheId: null
        , otftCacheTtl: '3600'
        }
    );
</script> """


viewPage :
    { projectName : String
    , snippetTop : String
    , snippetBottom : String
    , meta : PageMeta
    }
    -> String
viewPage { projectName, snippetTop, snippetBottom, meta } =
    """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>""" ++ meta.title ++ " - " ++ projectName ++ """</title>
    <style>body {font-family: sans-serif}</style>
</head>
<body>
    <header>
        <h1>""" ++ projectName ++ " - " ++ meta.title ++ """</h1>
        """ ++ snippetTop ++ """
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
    """ ++ snippetBottom ++ """
</body>
</html>"""


iif : Bool -> a -> a -> a
iif condition trueCase falseCase =
    if condition then
        trueCase

    else
        falseCase
