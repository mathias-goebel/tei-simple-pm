xquery version "3.0";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace app="http://www.tei-c.org/tei-simple/templates" at "app.xql";
import module namespace config="http://www.tei-c.org/tei-simple/config" at "config.xqm";

declare option output:method "json";
declare option output:media-type "application/json";

let $doc := request:get-parameter("doc", ())
let $root := request:get-parameter("root", ())
let $odd := request:get-parameter("odd", ())
let $id := request:get-parameter("id", ())
let $xml := 
    if ($id) then (
        console:log("Loading by id " || $id),
        let $node := doc($config:app-root || "/" || $doc)/id($id)
        let $div := $node/ancestor-or-self::tei:div[1]
        return
            if (empty($div)) then
                $node/following-sibling::tei:div[1]
            else
                $div
    ) else
        app:load-xml("div", $root, $doc)
return
    if ($xml) then
        let $parent := $xml/ancestor::tei:div[not(*[1] instance of element(tei:div))][1]
        let $prevDiv := $xml/preceding::tei:div[1]
        let $prev := app:get-previous(if ($parent and (empty($prevDiv) or $xml/.. >> $prevDiv)) then $xml/.. else $prevDiv)
        let $next := app:get-next($xml)
        let $html := app:process-content($odd, app:get-content($xml))
        let $doc := substring-after($doc, "/")
        return
            map {
                "doc": $doc,
                "odd": $odd,
                "next": 
                    if ($next) then 
                        $doc || "?root=" || util:node-id($next) || "&amp;odd=" || $odd
                    else (),
                "previous": 
                    if ($prev) then 
                        $doc || "?root=" || util:node-id($prev) || "&amp;odd=" || $odd
                    else (),
                "content": $html
            }
    else
        map { "error": "Not found" }