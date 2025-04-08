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
      , snippetBottom = \_ -> crowdinSnippet
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


crowdinSnippet : String
crowdinSnippet =
    """
<style>.js-proxy-blur {filter: blur(5px);}</style>
<script src="https://proxy-translator.app.crowdin.net/assets/proxy-translator.js"></script>
<script>
  window.proxyTranslator.init({
    baseUrl: "https://tkyodev.github.io/Uld4dElISnZZMnR6SVE/crowdin/",
    appUrl: "https://proxy-translator.app.crowdin.net",
    valuesParams: "U2FsdGVkX19qzZ1kRbQCVt8n1xqR9LzmZZkDZ/70p7gy90U4REqRvS0+OSQKzjLIlv13UApNFng2/L6HEvUKao5MUKLtzWaeZT2l222MGQlSP9L8HxrDDow3rLsiNYN3",
    distributionBaseUrl: "https://distributions.crowdin.net",
    filePath: "/tkyodev.github.io.json",
    distribution: "e-24ab64c6ec8b4bd5df303b3g0r",
    distributionSeparateFiles: false,
    languagesData: {"ko":{"code":"ko","name":"Korean","twoLettersCode":"ko"},"zh-CN":{"code":"zh-CN","name":"Chinese Simplified","twoLettersCode":"zh"},"zh-TW":{"code":"zh-TW","name":"Chinese Traditional","twoLettersCode":"zh"},"en":{"code":"en","name":"English","twoLettersCode":"en"},"ja":{"code":"ja","name":"Japanese","twoLettersCode":"ja"}},
    defaultLanguage: "ja",
    defaultLanguageTitle: "Japanese",
    languageDetectType: "default",
    poweredBy: true,
  });
</script> """


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

        otherPagesList : List ( String, String )
        otherPagesList =
            List.map (\otherPage -> ( folder ++ otherPage.name, otherPage.content )) otherPages
    in
    Json.Encode.object
        [ ( "removeFolders"
          , Json.Encode.list Json.Encode.string [ folder ]
          )
        , ( "addFiles"
          , Json.Encode.object
                (List.map (Tuple.mapSecond Json.Encode.string)
                    (topPage
                        :: style
                        :: otherPagesList
                        ++ pages_
                    )
                )
          )
        ]


otherPages : List { name : String, content : String }
otherPages =
    [ { name = "tester.html"
      , content =
            file_tester_html
                |> String.replace """<script src="../build-wc/web-components.min.js"></script>""" (loadScriptSkippingCache srcPreprodCanonical)
      }
    , { name = "tester-empty.html"
      , content = file_testerEmpty_html
      }
    , { name = "tester-with-iframes-etc.html"
      , content = file_testerWithIframesEtc_html
      }
    , { name = "GENERATED-test-list.js"
      , content = file_generatedTestList_js
      }
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
    <ul>"""
        ++ String.join "" (List.map (\site -> siteMenuLine site) (sites commit))
        ++ """</ul>
    <p>Others</p>
    <ul>
"""
        ++ String.join ""
            (List.map
                (\otherPage ->
                    "<li><a href='{name}'>{name}</a></li>\n"
                        |> String.replace "{name}" otherPage.name
                )
                otherPages
            )
        ++ """</ul>
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
        ++ "</li>\n"


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


loadScriptSkippingCache : String -> String
loadScriptSkippingCache src =
    """<script>
                const script = document.createElement('script');
                script.src = '""" ++ src ++ """?nocache=' + Math.random();
                script.async = true;
                document.head.appendChild(script);
            </script> """


extraCanonical : String -> String -> String
extraCanonical commit src =
    loadScriptSkippingCache src ++ """
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
            { src: '""" ++ src ++ """?nocache=' + Math.random()
            , async: true
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


file_tester_html : String
file_tester_html =
    --
    -- This file is originally in the `multilingual` repository.
    --
    -- Location: tests_/tester.html
    --
    -- Copy it from there when changed.
    --
    """
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="x-ua-compatible" content="ie=edge" />
    <meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no" />
    <title>Tester</title>
    <style>
      body {
        margin: 1rem;
        font-family: sans-serif;
        background-color: white;
        color: black;
      }

      /* Dark mode styles */
      @media (prefers-color-scheme: dark) {
        body {
          background-color: black;
          color: white;
        }
      }

      ul {
        padding-left: 0.8rem;
        font-family: monospace;
        font-size: 0.8rem;
      }

      ol {
        line-height: 1.5rem;
        font-size: 0.9rem;
      }

      h1 {
        margin: 0 0 1rem 0;
        font-size: 1.2rem;
      }

      :root {
        --spacing: 1rem;
      }

      r10-language-disclaimer {
        position: fixed;
        top: calc(var(--spacing) * 3);
        right: var(--spacing);
        margin-left: var(--spacing);
      }

      r10-language-selector {
        display: inline-block;
      }

      .a {font-size: 30px; background-color: yellow}

      .b {color: #2b2}

      .c {color: red}
    </style>
  </head>

  <body>
    <h1 id="test-name">Test not loaded yet</h1>
    <r10-language-selector></r10-language-selector>
    <div id="html-to-test-otft" style="display: none">
        <p><span class="a">この</span><a href="https://example.com" class="b">ページ</a><span class="c">を読んでください。</span></p>
        <p><span class="a">この<a href="https://example.com" class="b">メモ</a></span><span class="c">を読んでください。</span></p>
        <div class="notranslate">このテキストは翻訳されません (This text will NOT be translated)
            <div class="translate">これは翻訳されます
                <div class="notranslate">このテキストは翻訳されません (This text will NOT be translated)</div>
            </div>
        </div>
        <p><span>バナナ、</span><span>オレンジ、</span><span>リンゴ、</span><span>パイナップル、</span><span>ブドウ</span></p>
        <p>テキスト要素は1つだけ</p>
    </div>
    <r10-language-disclaimer></r10-language-disclaimer>
    <div id="query-params-container" style="overflow-wrap: break-word"></div>
    <script src="GENERATED-test-list.js"></script>
    <script>
      const currentUrlObj = new URL(location.href);
      const temp = new URLSearchParams(currentUrlObj.search);
      const queryParamsOriginal = {};
      const queryParamsForRedirects = {};
      const queryParamsForAttributes = {};
      temp.forEach((value, key) => {
        queryParamsOriginal[key] = value;
        queryParamsForRedirects[key] = value;
        queryParamsForAttributes[key] = value;
      });
      if (queryParamsOriginal["otft-api-url"] && queryParamsOriginal["otft-api-url"] !== "") {
        // We switch to OTFT testing mode
        document.getElementById('html-to-test-otft').style.display = 'block';
        document.getElementById('query-params-container').style.display = 'none';
      } 
      // Transforming back "lang='ja'" to "lang={{lang}}"
      // Is this really needed?
      queryParamsForRedirects["lang"] = "{{lang}}";
      //
      // There is another bug about {{lang}}. If we specify a different cookie
      // with "rlang={{lang}}; path=/; max-age=7776000; quantity=4",
      // it will be, after the redirect, replaced with
      // "rlang=en; path=/; max-age=7776000; quantity=4", for example.
      // This is because this string goes into the "redirects" value,
      // and it get automatically replaces with the language.
      // So probably in this case, needed to test cookies, is necessary to use
      // "prevent-default".
      //
      delete queryParamsForRedirects["clear-local-storage"];
      delete queryParamsForAttributes["clear-local-storage"];
      delete queryParamsForAttributes["lang"];
      const queryParamsForRedirectsObj = new URLSearchParams(
        queryParamsForRedirects
      );
      queryParamsForAttributes["redirects"] = decodeURIComponent(
        `?${queryParamsForRedirectsObj.toString()}`
      ).replace(",", "{{,}}");

      // Getting the current language from the local storage and setting it
      // in <html lang='xyz'>, as this value is used by the Language Selector.
      //
      // `lang-force` can be used to overwrite the langauge coming from the
      // local storage, if needed.
      //
      var lang = queryParamsOriginal["lang-force"] || localStorage.getItem("r10-lang") || queryParamsOriginal["lang"] || "en";
      if (lang) {
        document.documentElement.setAttribute("lang", lang);
        queryParamsForAttributes["selected-language"] = lang;
      }

      // Replace `navigator.languages` with the new values.
      // `navigator.languages` cannot be passed by attributes to the Language Selector.
      // The Language Selector always read this from `navigator.languages` directly
      // and it is passed as a flag into the Elm code.
      var languagesArray = queryParamsOriginal["navigator.languages"]
        ? queryParamsOriginal["navigator.languages"].split(",")
        : ["en"];
      Object.defineProperty(navigator, "languages", {
        get: function () {
          return languagesArray;
        },
      });

      // Updating components
      const languageSelector = document.querySelector("r10-language-selector");
      const languageDisclaimer = document.querySelector(
        "r10-language-disclaimer"
      );
      for (const [key, value] of Object.entries(queryParamsForAttributes)) {
        if (languageSelector) {
          languageSelector.setAttribute(key, value);
        }
        if (languageDisclaimer) {
          languageDisclaimer.setAttribute(key, value);
        }
      }

      let html = `<ul>
            <li><strong>Page language:</strong> ${lang}</li>
            <li><strong>navigator.languages:</strong> ${JSON.stringify(
              navigator.languages
            )}</li>
            <li><strong>localStorage.r10-lang:</strong> ${localStorage.getItem(
              "r10-lang"
            )}</li>
            <li><strong>localStorage.r10-notified-on:</strong> ${
              localStorage.getItem("r10-notified-on") ? "defined" : "null"
            }</li>
            <li><strong>localStorage.r10-recent-lang-change:</strong> ${
              localStorage.getItem("r10-recent-lang-change")
                ? "defined"
                : "null"
            }</li>
            `;
      for (const [key, value] of Object.entries(queryParamsOriginal)) {
        html += `<li><strong>param.${key}:</strong> ${value}</li>`;
      }
      html += '</ul><div class="hide-during-diffing"><h3>Test links</h3><ol>';
      const allDisclaimers = `disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ`;

      Object.entries(data).forEach(([testName, url]) => {
        html += `<li><a class="clear-local-storage" href=?${url}&testName=${encodeURIComponent(
          testName
        )}>${testName}</a></li>`;
      });

      html += "</ol></div>";
      document.getElementById("query-params-container").innerHTML = html;
      document.getElementById("test-name").innerText =
        queryParamsOriginal["testName"] || "Test name not available";
      const linksInDom = document.querySelectorAll(".clear-local-storage");

      // Add click event listener to each link
      linksInDom.forEach(function (link) {
        link.addEventListener("click", function (event) {
          localStorage.clear();
        });
      });
    </script>

    <script src="../build-wc/web-components.min.js"></script>

    <!-- <script src="../public/js/global.js"></script>
    <script src="../public/temp/GENERATED-meta-internal.js"></script>
    <script src="../public/temp/GENERATED-elm-web-components.js"></script>
    <script src="../public/js/thin-wrapper.js"></script>
    <script src="../public/js/_OTFT_debug.js"></script>
    <script src="../public/js/_OTFT_db.js"></script>
    <script src="../public/js/_OTFT_internal-translations.js"></script>
    <script src="../public/js/_OTFT_minification.js"></script>
    <script src="../public/js/_OTFT_fetch-translations.js"></script>
    <script src="../public/js/_OTFT_translate.js"></script>
    <script src="../public/js/_OTFT_inject-components.js"></script>
    <script src="../public/js/_OTFT_early-access.js"></script>
    <script src="../public/js/arranges-debuggers-side-by-side.js"></script> -->

  </body>
</html> """


file_testerEmpty_html : String
file_testerEmpty_html =
    --
    -- This file is originally in the `multilingual` repository.
    --
    -- Location: tests_/tester-empty.html
    --
    -- Copy it from there when changed.
    --
    """
<!DOCTYPE html>
<html lang="ja">
  <head>
    <meta charset="utf-8" />
    <meta http-equiv="x-ua-compatible" content="ie=edge" />
    <meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no" />
    <title>Tester Empty</title>
    <style>
      body {
        margin: 1rem;
        font-family: sans-serif;
        background-color: white;
        color: black;
      }

      .a {font-size: 30px; background-color: yellow}

      .b {color: #2b2}

      .c {color: red}
    </style>
  </head>

  <body>
    孤立した HTML 要素
    <p><span class="a">この</span><a href="https://example.com" class="b">ページ</a><span class="c">を読んでください。</span></p>
    <p><span class="a">この<a href="https://example.com" class="b">メモ</a></span><span class="c">を読んでください。</span></p>
    <div class="notranslate">このテキストは翻訳されません (This text will NOT be translated)
        <div class="translate">これは翻訳されます
            <div class="notranslate">このテキストは翻訳されません (This text will NOT be translated)</div>
        </div>
    </div>
    <p><span>バナナ、</span><span>オレンジ、</span><span>リンゴ、</span><span>パイナップル、</span><span>ブドウ</span></p>
    <p>テキスト要素は1つだけ</p>
    <script>
        // document.head.appendChild(Object.assign(document.createElement('script'),{ src:'http://127.0.0.1:8080/otft-early-access.min.js', onload:()=>{__otft_earlyAccess({ debug:'true', primaryColor:'pink', borderRadius:'5', withDisclaimer:'true', otftApiUrl:'https://translate-pa.googleapis.com/v1/translateHtml', otftContentType:'application/json+protobuf', otftKeyName:'x-goog-api-key', otftKeyValue:'VeBRlQYFma2pXUMRFRIVUUiNGcxBTSoVGM2dFRI12T1IDMBlkehN', otftMaxNumberOfTextNodes:'4', otftPath:'"*"', otftPayload:'[[[{{data}}],"{{source}}","{{target}}"],"te_lib"]' })}}));

        // document.head.appendChild(Object.assign(document.createElement('script'),{ src:'file:../build-wc/otft-early-access.min.js', onload:()=>{__otft_earlyAccess({ debug:'true', primaryColor:'pink', borderRadius:'5', withDisclaimer:'true', otftApiUrl:'https://translate-pa.googleapis.com/v1/translateHtml', otftContentType:'application/json+protobuf', otftKeyName:'x-goog-api-key', otftKeyValue:'VeBRlQYFma2pXUMRFRIVUUiNGcxBTSoVGM2dFRI12T1IDMBlkehN', otftMaxNumberOfTextNodes:'4', otftPath:'"*"', otftPayload:'[[[{{data}}],"{{source}}","{{target}}"],"te_lib"]' })}}));
    </script>
  </body>
</html> """


file_testerWithIframesEtc_html : String
file_testerWithIframesEtc_html =
    --
    -- This file is originally in the `multilingual` repository.
    --
    -- Location: tests_/tester-with-iframes-etc.html
    --
    -- Copy it from there when changed.
    --
    """
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="utf-8" />
    <meta http-equiv="x-ua-compatible" content="ie=edge" />
    <meta name="viewport" content="width=device-width,initial-scale=1,shrink-to-fit=no" />
    <title>テキスト 0.1</title>
    <meta name="description" content="テキスト 0.2">
    <meta name="keywords" content="テキスト 0.3">
    <meta name="twitter:title" content="テキスト 0.4">
    <meta name="twitter:description" content="テキスト 0.5">
    <meta property="og:title" content="テキスト 0.6">
    <meta property="og:description" content="テキスト 0.7">
    <meta property="og:site_name" content="テキスト 0.8">
    <style>
    body, select {font-family: monospace; font-size: 1.1rem}
    .notranslate {background-color:#dddd88; outline: 6px solid #aaaa00}
    h1 {font-size: 1.4rem}
    iframe {height: 140px}
    </style>
</head>

<body>
    <h1 class="notranslate">OTFT test page for iframes, attributes, etc.</h1>
    <p class="notranslate">1. &lt;INPUT&gt; type="text" with placeholder</p>
    <input type="text" placeholder="テキスト 1.0" />
    <p class="notranslate">2. &lt;INPUT&gt; type="submit"</p>
    <input type="submit" value="テキスト 2.0" />
    <p class="notranslate">3. &lt;INPUT&gt; type="reset"</p>
    <input type="reset" value="テキスト 3.0" />
    <p class="notranslate">4. &lt;INPUT&gt; type="button"</p>
    <input type="button" value="テキスト 4.0" />
    <p class="notranslate">5. &lt;INPUT&gt; type=text with placeholder and class=notranslate</p>
    <input type="text" placeholder="テキスト 5.0" class="notranslate" /></div>
    <p class="notranslate">6. &lt;DIV&gt; with "aria-label", "aria-roledescription", "aria-valuetext", and "aria-description"</p>
    <div aria-label="テキスト 6.1" aria-roledescription="テキスト 6.2" aria-valuetext="テキスト 6.3" aria-description="テキスト 6.4">テキスト 6.5</div>
    <p class="notranslate">7. &lt;IFRAME&gt; with srcdoc</p>
    <iframe srcdoc='<p>テキスト 7.1</p><input type="text" placeholder="テキスト 7.2" />' style="height: 90px"></iframe>
    <p class="notranslate">8. &lt;IFRAME&gt; with a nested &lt;IFRAME&gt; with srcdoc</p>
    <iframe srcdoc='<p>テキスト 8.1</p><iframe srcdoc="&lt;p&gt;テキスト 8.2&lt;/p&gt; &lt;input type=&amp;quot;text&amp;quot; placeholder=&amp;quot;テキスト 8.3&amp;quot; /&gt;"></iframe>'></iframe>
    <p class="notranslate">9. &lt;IFRAME&gt; with content from different origin</p>
    <iframe src='https://tkyodev.github.io/Uld4dElISnZZMnR6SVE/canonical/index.html'></iframe>
    <p class="notranslate">10. &lt;CODE&gt;</p>
    <code>テキスト 10.1 <span>テキスト 10.2</span></code>
    <p class="notranslate">11. &lt;TEXTAREA&gt;</p>
    <textarea>テキスト 11.1</textarea>
    <p class="notranslate">12. &lt;IMG&gt; with alt and title</p>
    <img src="smily.webp" alt="テキスト 12.1" title="テキスト 12.2" style="width: 30px">
    <p class="notranslate">13. &lt;LABEL&gt;, &lt;SELECT&gt; and &lt;OPTION&gt;s</p>
    <label for="pet-select">テキスト 13.1</label>
    <select id="pet-select">
        <option value="">テキスト 13.2</option>
        <option value="テキスト 13.a">テキスト 13.3</option>
        <option value="テキスト 13.b">テキスト 13.4</option>
        <option value="テキスト 13.c">テキスト 13.5</option>
    </select>

    <script>
        // Simulating WOVN
        WOVN = 
            { io: 
                { changeLang: (item) => {console.log(`<WOVN FAKE FUNCTION WOVN.io.changeLang("${item}")>`)} 
                , optOut: () => {console.log(`<WOVN FAKE FUNCTION WOVN.io.optOut()>`)}
                }
            };
    </script>
</body>
</html> """


file_generatedTestList_js : String
file_generatedTestList_js =
    --
    -- This file is originally in the `multilingual` repository.
    --
    -- Location: GENERATED-test-list.js
    --
    -- Copy it from there when changed.
    --
    """
data={
    "P6v Font large": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&style=font-size:1.3rem",
    "L8t Font small": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&style=font-size:0.8rem",
    "G7r Custom style": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&style=--r10-button-color-light-background:rgb(0,255,255);--r10-button-color-dark-background:rgb(0,255,255)",
    "V9m Border rounded (pill)": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&modality=open&border-radius=50",
    "B4q Menu Only": "menu-only&modality=open&modality-disclaimer=close",
    "T5x Max height 120px": "max-height-menu=120&modality=open&modality-disclaimer=close",
    "K7n Only English, Japanese": "modality=open&supported-languages=en,ja",
    "M3p Very long service name": "service-name=ThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpaces&disclaimer-custom=ThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpaces",
    "N9g [Mobile] Very long service name": "style=bottom:1rem;left:1rem;margin-right:1rem;top:auto;right:auto;margin-left:auto&service-name=ThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpaces&disclaimer-custom=ThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpacesThisIsAVeryLongTextWithoutSpaces",
    "F6c [Mobile] Disclaimer with picker, full": "style=bottom:1rem;left:1rem;margin-right:1rem;top:auto;right:auto;margin-left:auto&disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ",
    "W8y [Mobile] Disclaimer without picker, full": "style=bottom:1rem;left:1rem;margin-right:1rem;top:auto;right:auto;margin-left:auto&disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&modality-disclaimer=openWithoutLanguageSelector",
    "K2h [Large] Contain all supported languages": "modality=open&supported-languages=en,ja,zh-cn,zh-tw,zh-HK,de,es,it,pt,nl,uk,fr,id,ko,th",
    "bA7 Contain a supported language": "modality=open&supported-languages=ja",
    "X5z Contain two supported languages": "modality=open&supported-languages=ja,es",
    "gT3 Contain an unsupported language": "modality=open&supported-languages=no|Norwegian",
    "V4p Contain two same languages": "modality=open&supported-languages=zh-tw,zh-tw",
    "M9q Incorrect uppercase and lowercase": "modality=open&supported-languages=ZH-TW",
    "w8C Full-width characters check": "modality=open&supported-languages=ｊａ",
    "G8f Supported languages value is empty": "modality=open&supported-languages=",
    "tR7 Contain irregular value": "modality=open&supported-languages=123",
    "L6f Default value check": "modality=open",
    "P7m Contain a supported language": "modality=open&lang=ja",
    "k9B Contain two supported languages": "modality=open&lang=ja,en",
    "D5n Incorrect uppercase and lowercase": "modality=open&supported-languages=ja&lang=Ja",
    "R7x Incorrect uppercase and lowercase": "modality=open&supported-languages=Ja&lang=Ja",
    "N3q Contain irregular value": "modality=open&lang=123",
    "v6Y Contain a supported language and an unsupported language": "modality=open&supported-languages=zh-tw,no|Norwegian&lang=no|Norwegian",
    "J9k Supported languages dont contain Current languages": "modality=open&supported-languages=ja,en,zh-Hant,zh-Hans,ko&lang=es",
    "h4Z Default value check": "modality=open&supported-languages=ja,en,zh-Hant,zh-Hans,ko",
    "T6y Light Theme": "modality=open&selected-theme=light",
    "R9s Dark Theme": "modality=open&selected-theme=dark",
    "j3K Contain irregular value": "modality=open&selected-theme=123",
    "Q8v Primary Color is red": "modality=open&primary-color=red",
    "h7F Primary Color is orange": "modality=open&primary-color=orange",
    "N5q Primary Color is green": "modality=open&primary-color=green",
    "m3X Primary Color is light-blue": "modality=open&primary-color=light-blue",
    "C4t Primary Color is blue": "modality=open&primary-color=blue",
    "v7L Primary Color is purple": "modality=open&primary-color=purple",
    "H9k Primary Color is pink": "modality=open&primary-color=pink",
    "B6y Primary Color is black": "modality=open&primary-color=black",
    "f2D Contain two supported values": "modality=open&primary-color=pink,green",
    "S8p Contain unsupported value": "modality=open&primary-color=yellow",
    "z3M Contain irregular value": "modality=open&primary-color=123",
    "W7g Extra character to valid color": "modality=open&primary-color=purplee",
    "Y9b Default Value Check": "modality=open",
    "Q8p Set Small value": "modality=open&border-radius=10",
    "T6x Set Large value": "modality=open&border-radius=1000",
    "N9v Contain unsupported value": "modality=open&border-radius=1000.5",
    "M5t Contain irregular value": "modality=open&border-radius=abc",
    "D7r Default value check": "modality=open",
    "R8h Set Menu to True": "modality=open&menu-only=True",
    "V7k Set Menu to False": "modality=open&menu-only=False",
    "X5q Menu Only OFF(Default)": "modality=open",
    "G9s font-size 20px": "modality=open&style=font-size:20px;",
    "M8f color purple": "modality=open&style=color:purple;",
    "B6p background-color purple": "modality=open&style=background-color:purple;",
    "T3y --r10-button-color-light-font purple": "modality=open&style=--r10-button-color-light-font:purple;",
    "W9m --r10-button-color-light-background": "modality=open&style=--r10-button-color-light-background:purple;",
    "K7b --r10-button-color-light-outline": "modality=open&style=--r10-button-color-light-outline:purple;",
    "S6x --r10-button-color-dark-font": "modality=open&style=--r10-button-color-dark-font:purple;",
    "P9v --r10-button-color-dark-background": "modality=open&style=--r10-button-color-dark-background:purple;",
    "J8w --r10-button-color-dark-outline": "modality=open&style=--r10-button-color-dark-outline:purple;",
    "K9h No CSS Style set(Default)": "modality=open",
    "R5t Max Height set above required length": "modality=open&max-height-menu=500",
    "W8n Max Height set below required length": "modality=open&max-height-menu=100",
    "Q7p Max Height set to 0": "modality=open&max-height-menu=0",
    "J4m Max height not set(Default)": "modality=open",
    "V9g [Large] Contain all supported languages": "modality=open&supported-languages=en,ja,zh-cn,zh-tw,zh-HK,de,es,it,pt,nl,uk,fr,id,ko,th",
    "X7r Contain a supported language": "modality=open&supported-languages=ja",
    "M8t Contain two supported languages": "modality=open&supported-languages=ja,es",
    "G5n Contain an unsupported language": "modality=open&supported-languages=no|Norwegian",
    "B9v Change known language display name": "modality=open&supported-languages=ja|Norwegian",
    "K6p Contain two same languages": "modality=open&supported-languages=zh-tw,zh-tw",
    "T3f Incorrect uppercase and lowercase": "modality=open&supported-languages=ZH-TW",
    "L7w Full-width characters check": "modality=open&supported-languages=ｊａ",
    "P9h Supported languages value is empty": "modality=open&supported-languages=",
    "H8q Contain irregular value": "modality=open&supported-languages=123",
    "S4m Default value check": "modality=open",
    "N6v Contain a supported language": "modality=open&lang=ja",
    "K8t Contain two supported languages": "modality=open&lang=ja,en",
    "G5p Incorrect uppercase and lowercase": "modality=open&supported-languages=ja&lang=Ja",
    "M9r Incorrect uppercase and lowercase": "modality=open&supported-languages=Ja&lang=Ja",
    "B7q Contain irregular value": "modality=open&lang=123",
    "W8f Contain a supported languages and an unsupported language": "modality=open&supported-languages=zh-tw,no|Norwegian&lang=no|Norwegian",
    "T9k Supported languages don't contain Current languages": "modality=open&supported-languages=ja,en,zh-Hant,zh-Hans,ko&lang=es",
    "D3n Default value check": "modality=open&supported-languages=ja,en,zh-Hant,zh-Hans,ko",
    "L7n Primary Color is red": "modality=open&primary-color=red",
    "T6y Primary Color is orange": "modality=open&primary-color=orange",
    "M9h Primary Color is green": "modality=open&primary-color=green",
    "K8r Primary Color is light-blue": "modality=open&primary-color=light-blue",
    "D3p Primary Color is blue": "modality=open&primary-color=blue",
    "V9f Primary Color is purple": "modality=open&primary-color=purple",
    "R7k Primary Color is pink": "modality=open&primary-color=pink",
    "N8w Primary Color is black": "modality=open&primary-color=black",
    "Q5t Contain two supported values": "modality=open&primary-color=pink,green",
    "X4m Contain unsupported value": "modality=open&primary-color=yellow",
    "P6g Contain irregular value": "modality=open&primary-color=123",
    "W9b Extra character to valid color": "modality=open&primary-color=purplee",
    "F7q Default Value Check": "modality=open",
    "G8p Set common Service name": "service-name=Rakuten Market Place",
    "R9t Set different values for different languages": "service-name=en|Rakuten Market Place, ja|楽天市場, ko | 안녕하세요",
    "M7n No language": "",
    "V6k Default Service name": "",
    "X8m Set 'Japan Only' disclaimer": "disclaimer-japan-only",
    "T7r Default 'Japan Only' disclaimer": "",
    "K9p Set 'Base' disclaimer": "disclaimer-base",
    "W4f Default 'Base' disclaimer": "",
    "Q6n Set 'Partially Translated' disclaimer": "disclaimer-partially-translated",
    "P3g Default 'Partially Translated' disclaimer": "",
    "D9v Set 'Partially Translated Including Customer Support' disclaimer with 'Partially Translated' disclaimer": "disclaimer-partially-translated&disclaimer-partially-translated-including-cs",
    "N7k Set 'Partially Translated Including Customer Support' disclaimer": "disclaimer-partially-translated-including-cs",
    "F5b Default 'Partially Translated Including Customer Support' disclaimer": "",
    "H8t Set 'Custom' disclaimer": "disclaimer-custom=Hi..Thanks for visiting",
    "L6w Default 'Custom' disclaimer": "",
    "S9c Set all disclaimers": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated&disclaimer-partially-translated-including-cs&disclaimer-custom=Hi..Thanks for visting",
    "Y3r Font-size": "style=font-size:14px;",
    "Z8p --r10-button-color-light-background: purple": "style=--r10-button-color-light-background:purple;",
    "J7q --r10-button-color-dark-background: purple": "style=--r10-button-color-dark-background:purple;",
    "B5g No CSS style": "",
    "V4n Set 'Notify From' to past time": "notify-from=1721798630000",
    "G9x Set 'Notify From' to future time": "notify-from=5000000000000",
    "C6d Set Small value": "border-radius=10",
    "M8f Set Large value": "border-radius=100",
    "R7y Contain unsupported value": "border-radius=100.5",
    "X3t Contain irregular value": "border-radius=12q",
    "W9m Default value check": "",
    "D7k Disclaimer with picker, full, ENGLISH": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&navigator.languages=en",
    "D7k Disclaimer with picker, full, KOREAN": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&navigator.languages=ko",
    "D7k Disclaimer with picker, full, SIMPLIFIED": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&navigator.languages=zh-Hans",
    "D7k Disclaimer with picker, full, TRADITIONAL": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&navigator.languages=zh-Hant",
    "H9b Disclaimer with picker, custom, no service name, ENGLISH": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&navigator.languages=en",
    "H9b Disclaimer with picker, custom, no service name, KOREAN": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&navigator.languages=ko",
    "H9b Disclaimer with picker, custom, no service name, SIMPLIFIED": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&navigator.languages=zh-Hans",
    "H9b Disclaimer with picker, custom, no service name, TRADITIONAL": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&navigator.languages=zh-Hant",
    "S4v Disclaimer without picker, full, ENGLISH": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&modality-disclaimer=openWithoutLanguageSelector&lang=en",
    "S4v Disclaimer without picker, full, KOREAN": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&modality-disclaimer=openWithoutLanguageSelector&lang=ko",
    "S4v Disclaimer without picker, full, SIMPLIFIED": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&modality-disclaimer=openWithoutLanguageSelector&lang=zh-Hans",
    "S4v Disclaimer without picker, full, TRADITIONAL": "disclaimer-japan-only&disclaimer-base&disclaimer-partially-translated-including-cs&service-name=XYZ&modality-disclaimer=openWithoutLanguageSelector&lang=zh-Hant",
    "X5f Disclaimer without picker, custom, no service name, ENGLISH": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&modality-disclaimer=openWithoutLanguageSelector&lang=en",
    "X5f Disclaimer without picker, custom, no service name, KOREAN": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&modality-disclaimer=openWithoutLanguageSelector&lang=ko",
    "X5f Disclaimer without picker, custom, no service name, SIMPLIFIED": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&modality-disclaimer=openWithoutLanguageSelector&lang=zh-Hans",
    "X5f Disclaimer without picker, custom, no service name, TRADITIONAL": "disclaimer-custom=This%20is%20a%20custom%20agreement%20for%20ENGLISH.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Cko%7CThis%20is%20a%20custom%20agreement%20for%20KOREAN.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-TW%7CThis%20is%20a%20custom%20agreement%20for%20TRADITIONAL%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.%2Czh-CN%7CThis%20is%20a%20custom%20agreement%20for%20SIMPLIFIED%20CHINESE.%20Lorem%20ipsum%20dolor%20sit%20amet%7B%7B%2C%7D%7D%20consectetur%20adipiscing%20elit.%20Cras%20quis%20erat%20pulvinar%20neque%20pulvinar%20commodo.%20Etiam%20at%20fringilla%20magna.%20Curabitur%20pharetra%20sollicitudin%20ex%20eu%20dignissim.&modality-disclaimer=openWithoutLanguageSelector&lang=zh-Hant"
} """
