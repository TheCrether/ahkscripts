#Include "./Base.ahk"
#Include "./JXON.ahk"

DoRequest(url, method := "GET", body := {}) {
	req := ComObject('Msxml2.XMLHTTP')
	req.open(method, url, false)
	req.send() ; TODO add possiblity of sending a body https://learn.microsoft.com/en-us/previous-versions/windows/desktop/ms763706(v=vs.85)
	if req.status != 200
		throw Error(req.status ' - ' req.statusText, -1)

	return req.responseText
}

GetJSON(url, method := "GET") {
	res := DoRequest(url, method)
	return Jxon_Load(&res)
}