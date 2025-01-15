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


type alias Site =
    { path : String
    , snippetBottom : String -> String
    , snippetMeta : String
    , snippetTop : String -> String
    , scriptSrc : String
    , name : String
    }


sites : String -> List Site
sites commit =
    [ { path = "plain"
      , snippetTop = \_ -> ""
      , snippetBottom = \_ -> ""
      , snippetMeta = ""
      , scriptSrc = ""
      , name = "Plain"
      }
    , { path = "canonical"
      , snippetTop = extraCanonical commit
      , snippetBottom = \_ -> ""
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcPreprodCanonical
      , name = "Canonical"
      }
    , { path = "bookmarklet"
      , snippetTop = \_ -> ""
      , snippetBottom = extraBookmarklet commit
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcPreprodBookmarklet
      , name = "Bookmarklet"
      }
    , { path = "canonical_dev"
      , snippetTop = extraCanonical commit
      , snippetBottom = \_ -> ""
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcLocalCanonical
      , name = "Canonical (DEV)"
      }
    , { path = "bookmarklet_dev"
      , snippetTop = \_ -> ""
      , snippetBottom = extraBookmarklet commit
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcLocalBookmarklet
      , name = "Bookmarklet (DEV)"
      }
    , { path = "wovn"
      , snippetTop = extraCanonical commit
      , snippetBottom = \_ -> ""
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcPreprodCanonical
      , name = "Wovn (WIP)"
      }
    , { path = "crowdin"
      , snippetTop = extraCanonical commit
      , snippetBottom = \_ -> ""
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcPreprodCanonical
      , name = "Crowdin (WIP)"
      }
    , { path = "shutto"
      , snippetTop = extraCanonical commit
      , snippetBottom = \_ -> ""
      , snippetMeta = snippetMetaGoogleNoTranslate
      , scriptSrc = srcPreprodCanonical
      , name = "Shutto (WIP)"
      }
    ]


folder : String
folder =
    "docs/"


main_ : Flags -> Json.Encode.Value
main_ flags =
    let
        pages_ : List ( String, String )
        pages_ =
            List.concat
                (List.map
                    siteToPages
                    (sites flags.commit)
                )

        topPage : ( String, String )
        topPage =
            ( folder ++ "index.html"
            , indexHtml flags.commit
            )

        style : ( String, String )
        style =
            ( folder ++ "style.css"
            , styleCss
            )
    in
    Json.Encode.object
        [ ( "removeFolders"
          , Json.Encode.list Json.Encode.string [ folder ]
          )
        , ( "addFiles"
          , Json.Encode.object (List.map (Tuple.mapSecond Json.Encode.string) (topPage :: style :: pages_))
          )
        ]


indexHtml : String -> String
indexHtml commit =
    """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Top</title>
    <link rel="stylesheet" href="style.css"></head>
<body>
    <ul>""" ++ String.join "" (List.map (\site -> siteMenuLine site) (sites commit)) ++ """</ul>
</body>
</html>"""


siteMenuLine : Site -> String
siteMenuLine site =
    let
        script =
            if String.isEmpty site.scriptSrc then
                ""

            else
                " - <a class='small' target='_blank' href='"
                    ++ site.scriptSrc
                    ++ "'>"
                    ++ site.scriptSrc
                    ++ "</a>"
    in
    "<li><a href='"
        ++ site.path
        ++ "/index.html'>"
        ++ site.name
        ++ "</a>"
        ++ script
        ++ "</li>"


snippetMetaGoogleNoTranslate : String
snippetMetaGoogleNoTranslate =
    """<meta name="google" content="notranslate">"""


srcLocalBookmarklet : String
srcLocalBookmarklet =
    "http://127.0.0.1:8080/otft-early-access.min.js"


srcLocalCanonical : String
srcLocalCanonical =
    "http://127.0.0.1:8080/web-components.min.js"


srcPreprodBookmarklet : String
srcPreprodBookmarklet =
    "https://membership.rakuten-static.com/pre/ml/otft-early-access.min.js"


srcPreprodCanonical : String
srcPreprodCanonical =
    "https://membership.rakuten-static.com/pre/ml/web-components.min.js"


pages : Pages
pages =
    { index = { title = "トップページ", sentence = "参照透過性とは、同じ値を与えたら返り値も必ず同じになるような性質である。" }
    , subpage1 = { title = "サブページ1", sentence = "参照透過性を持つことは、その関数が状態を持たないことを保証する。" }
    , subpage2 = { title = "サブページ2", sentence = "状態を持たない数学的な関数は、並列処理を実現するのに適している。" }
    }


siteToPages : Site -> List ( String, String )
siteToPages args =
    [ ( folder ++ args.path ++ "/index.html"
      , viewPage args pages.index
      )
    , ( folder ++ args.path ++ "/subpage1.html"
      , viewPage args pages.subpage1
      )
    , ( folder ++ args.path ++ "/subpage2.html"
      , viewPage args pages.subpage2
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


asStringForJavaScript : String -> String
asStringForJavaScript string =
    Json.Encode.encode 0 <| Json.Encode.string string


asStringForHtml : String -> String
asStringForHtml string =
    "\"" ++ String.replace "\"" "&quot;" string ++ "\""


attrs :
    { debug : String
    , otftApiUrl : String
    , otftCacheId : String
    , otftCacheTtl : String
    , otftContentType : String
    , otftKeyName : String
    , otftKeyValue : String
    , otftMaxNumberOfTextNodes : String
    , otftPath : String
    , otftPayload : String
    , primaryColor : String
    , selectedTheme : String
    , withDisclaimer : String
    }
attrs =
    { primaryColor = "blue"
    , selectedTheme = "light"
    , withDisclaimer = "true"
    , debug = "true"
    , otftApiUrl = "https://translate-pa.googleapis.com/v1/translateHtml"
    , otftContentType = "application/json+protobuf"
    , otftKeyName = "x-goog-api-key"
    , otftKeyValue = "VeBRlQYFma2pXUMRFRIVUUiNGcxBTSoVGM2dFRI12T1IDMBlkehN"
    , otftMaxNumberOfTextNodes = "8"
    , otftPath = "\"*\""
    , otftPayload = """[[[{{data}}],"{{source}}","{{target}}"],"te_lib"]"""
    , otftCacheId = "abc123"
    , otftCacheTtl = "3600"
    }


extraCanonical : String -> String -> String
extraCanonical commit src =
    "<script src='" ++ src ++ "?" ++ commit ++ """' async></script>
            <r10-language-selector
                selected-theme=""" ++ asStringForHtml attrs.selectedTheme ++ """
                debug=""" ++ asStringForHtml attrs.debug ++ """
                otft-api-url=""" ++ asStringForHtml attrs.otftApiUrl ++ """
                otft-content-type=""" ++ asStringForHtml attrs.otftContentType ++ """
                otft-key-name=""" ++ asStringForHtml attrs.otftKeyName ++ """
                otft-key-value=""" ++ asStringForHtml attrs.otftKeyValue ++ """
                otft-max-number-of-text-nodes=""" ++ asStringForHtml attrs.otftMaxNumberOfTextNodes ++ """
                otft-path=""" ++ asStringForHtml attrs.otftPath ++ """
                otft-payload=""" ++ asStringForHtml attrs.otftPayload ++ """
                otft-cache-id=""" ++ asStringForHtml attrs.otftCacheId ++ """
                otft-cache-ttl=""" ++ asStringForHtml attrs.otftCacheTtl ++ """
            >
            </r10-language-selector> """


extraBookmarklet : String -> String -> String
extraBookmarklet commit src =
    -- http://127.0.0.1:8080/otft-early-access.min.js
    """<script>
        document.head.appendChild(Object.assign(document.createElement('script'), 
            { src: '""" ++ src ++ "?" ++ commit ++ """'
            , onload: () => {
                __otft_earlyAccess(
                    { debug: """ ++ asStringForJavaScript attrs.debug ++ """
                    , primaryColor: """ ++ asStringForJavaScript attrs.primaryColor ++ """
                    , supportedLanguages: 'ja, en, zh-Hant, zh-Hans, ko'
                    , borderRadius: '5'
                    , withDisclaimer: """ ++ asStringForJavaScript attrs.withDisclaimer ++ """
                    , otftApiUrl: """ ++ asStringForJavaScript attrs.otftApiUrl ++ """
                    , otftContentType: """ ++ asStringForJavaScript attrs.otftContentType ++ """
                    , otftKeyName: """ ++ asStringForJavaScript attrs.otftKeyName ++ """
                    , otftKeyValue: """ ++ asStringForJavaScript attrs.otftKeyValue ++ """
                    , otftMaxNumberOfTextNodes: """ ++ asStringForJavaScript attrs.otftMaxNumberOfTextNodes ++ """
                    , otftPath: """ ++ asStringForJavaScript attrs.otftPath ++ """
                    , otftPayload: """ ++ asStringForJavaScript attrs.otftPayload ++ """
                    }
                )
            }
        }));
    </script>"""


viewPage : Site -> PageMeta -> String
viewPage site meta =
    """<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    """ ++ site.snippetMeta ++ """
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>""" ++ meta.title ++ " - " ++ site.name ++ """</title>
    <link rel="stylesheet" href="../style.css">
</head>
<body>
    <header>
        <div id="top-header">
            <div><a id="home-icon" href="..">⌂</a> ❯ """ ++ String.replace "_" " " site.name ++ """</div>
            """ ++ site.snippetTop site.scriptSrc ++ """
        </div>
        <div id="sub-header">
            <h1>""" ++ meta.title ++ """</h1>
            <nav>
                <ul>
                    <li>""" ++ iif (meta == pages.index) ("<b>" ++ meta.title ++ "</b>") ("<a href='index.html'>" ++ pages.index.title ++ "</a>") ++ """</li>
                    <li>""" ++ iif (meta == pages.subpage1) ("<b>" ++ meta.title ++ "</b>") ("<a href='subpage1.html'>" ++ pages.subpage1.title ++ "</a>") ++ """</li>
                    <li>""" ++ iif (meta == pages.subpage2) ("<b>" ++ meta.title ++ "</b>") ("<a href='subpage2.html'>" ++ pages.subpage2.title ++ "</a>") ++ """</li>
                </ul>
            </nav>
        </div>
    </header>
    <main>
        <p>""" ++ meta.sentence ++ """</p>
    </main>
    """ ++ site.snippetBottom site.scriptSrc ++ """
</body>
</html>"""


iif : Bool -> a -> a -> a
iif condition trueCase falseCase =
    if condition then
        trueCase

    else
        falseCase


styleCss : String
styleCss =
    """body 
    { font-family: sans-serif
    ; font-size: 1rem
    ; margin: 1rem
    }

ul 
    { line-height: 2rem
    }

.small 
    { font-size: 0.8rem
    }

#home-icon
    { font-size: 1.5rem
    ; font-weight: bold
    ; text-decoration: none
    }
    

#top-header   
    { display: flex
    ; align-items: center
    ; width: fill
    ; justify-content: space-between
    ; border-bottom: 1px solid rgba(0, 0, 0, 0.2)
    ; padding-bottom: 0.5rem
    }
    
nav > ul 
    { display: flex;
    ; align-items: center
    ; list-style-type: none
    ; margin: 0
    ; padding: 0
    ; gap: 0.4rem
    ; font-size: 0.9rem
    }
    
nav > ul > li
    { border: 1px solid rgba(0, 0, 0, 0.2)
    ; background-color: rgba(0, 0, 0, 0.05)
    ; text-decoration: none
    ; padding: 0 0.4rem
    ; margin: 0
    }    

nav > ul > li > a
    { text-decoration: none
    }    
    
main
    { line-height: 1.8rem
    }"""
