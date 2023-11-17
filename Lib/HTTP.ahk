#Include "./Base.ahk"
#Include "./Jsons.ahk"

setupReloadPaths(A_ScriptDir . "\Lib\HTTP.ahk")

DoRequest(url, method := "GET", body := "", applicationType := "application/json") {
	req := ComObject('Msxml2.XMLHTTP')
	method := StrUpper(method)
	if body {
		if method = "GET" {
			throw Error("can't use GET with body")
		}
		req.open(method, url, false)
		req.setRequestHeader("Content-Type", applicationType)
		if applicationType = "application/json" and (body is Array or body is Object or body is Map) {
			body := Jsons.Dump(body)
		}
		req.send(body)
	} else {
		req.open(method, url, false)
		req.send()
	}
	if req.status != 200
		throw Error(req.status ' - ' req.statusText, -1)

	return req.responseText
}

GetJSON(url, method := "GET") {
	res := DoRequest(url, method)
	return Jsons.Load(&res)
}