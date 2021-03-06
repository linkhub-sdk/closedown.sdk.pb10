$PBExportHeader$closedown.sru
forward
global type closedown from nonvisualobject
end type
end forward

global type closedown from nonvisualobject
end type
global closedown closedown

type variables
private:
Constant String ServiceID = "CLOSEDOWN"
constant string ServiceURL= "https://closedown.linkhub.co.kr"
constant string APIVersion = "1.0"

protected:
token in_token
authority in_authority
closedownexception exception

public:
string linkID
string secretKey
string scopes[]

end variables

forward prototypes
private function authority getauthority () throws closedownexception
protected function string getserviceurl ()
private function string getsessiontoken () throws closedownexception
public function double getbalance () throws closedownexception
protected function any parsejson (string inputjson) throws closedownexception
protected function any httpget (string url) throws closedownexception
protected function any httppost (string url, string postdata) throws closedownexception
public function decimal getunitcost () throws closedownexception
public function corpstate checkCorpNum(string corpNum) throws closedownexception
public subroutine checkCorpNums (ref string mgtkeylist[], ref corpstate ref_returnlist[]) throws closedownexception

public function corpstate tocorpstate(ref oleobject dic)
end prototypes

private function authority getauthority () throws closedownexception;if isnull(in_authority) then
	if isnull(linkid) or linkID = "" then throw exception.setCodeNMessage(-99999999,"링크아이디가 입력되지 않았습니다.")
	if isnull(secretKey) or secretKey = "" then throw exception.setCodeNMessage(-99999999,"비밀키가 입력되지 않았습니다.")
	in_authority = create authority
	in_authority.linkid = linkid
	in_authority.secretkey = secretKey
end if

return in_authority
end function

protected function string getserviceurl();
	return serviceurl
end function

private function string getsessiontoken () throws closedownexception;
boolean changed,expired
DateTime now

expired = true

if not changed and isnull(in_token) = false then
	try 
		now = DateTime(date(mid(getAuthority().getTime(),1,10)) ,time( mid(getAuthority().getTime(),12,8)))
	catch (linkhubexception ex)
		throw exception.setCodeNMessage(ex.getcode(),ex.getmessage())
	end try
	expired = DateTime(date(mid(in_token.expiration,1,10)) ,time( mid(in_token.expiration,12,8))) <  now
end if

if expired then
	try
		in_token = getauthority().gettoken(ServiceID,"",scopes,"")
	catch (linkhubexception le)
		throw exception.setCodeNMessage(le.getcode(),le.getmessage())
	end try
end if

return in_token.session_token
end function

public function double getbalance () throws closedownexception;try
	return  getAuthority().getPartnerBalance(getsessionToken(),ServiceID)
catch(linkhubexception le)
	throw exception.setcodenmessage(le.getcode(),le.getmessage())
end try
end function

protected function any parsejson (string inputjson) throws closedownexception;try
	return getauthority().parsejson(inputjson)
catch(linkhubexception le)
	throw exception.setcodenmessage(le.getcode(),le.getmessage())
end try
end function

protected function any httpget (string url) throws closedownexception;OLEObject lo_httpRequest,dic
any anyReturn
string ls_result

lo_httpRequest = CREATE OLEObject
if lo_httpRequest.ConnectToNewObject("MSXML2.XMLHTTP.6.0") <> 0 then throw exception.setCodeNMessage(-99999999,"HttpRequest Create Fail.")
lo_httpRequest.open("GET",getServiceURL() + url,false)
lo_httpRequest.setRequestHeader("Authorization","Bearer " + getsessionToken())
lo_httpRequest.setRequestHeader("Accept-Encoding","gzip,deflate")
lo_httpRequest.setRequestHeader("Content-Type", "Application/json")
lo_httpRequest.send()

ls_result = string(lo_httpRequest.ResponseText)

if lo_httpRequest.Status <> 200 then 
	dic = parsejson(ls_result)
	exception.setCodeNMessage(dic.Item("code"),dic.Item("message"))
	lo_httpRequest.DisconnectObject()
	destroy lo_httpRequest
	dic.DisconnectObject()
	destroy dic
	throw exception
end if

lo_httpRequest.DisconnectObject()
destroy lo_httpRequest

anyReturn = parsejson(ls_result)
return anyReturn
end function

protected function any httppost (string url, string postdata) throws closedownexception;OLEObject lo_httpRequest, dic
any returnobj
string ls_result

lo_httpRequest = CREATE OLEObject
if lo_httpRequest.ConnectToNewObject("MSXML2.XMLHTTP.6.0") <> 0 then throw exception.setCodeNMessage(-99999999,"HttpRequest Create Fail.")
lo_httpRequest.open("POST",getServiceURL() + url,false)
lo_httpRequest.setRequestHeader("Content-Type", "Application/json")
lo_httpRequest.setRequestHeader("Accept-Encoding","gzip,deflate")
lo_httpRequest.setRequestHeader("Authorization","Bearer " + getsessionToken())

lo_httpRequest.send(postData)

ls_result = string(lo_httpRequest.ResponseText)

if lo_httpRequest.Status <> 200 then 
	dic = parsejson(ls_result)
	exception.setCodeNMessage(dic.Item("code"),dic.Item("message"))
	lo_httpRequest.DisconnectObject()
	destroy lo_httpRequest
	dic.DisconnectObject()
	destroy dic
	throw exception
end if

lo_httpRequest.DisconnectObject()
destroy lo_httpRequest

returnobj = parsejson(ls_result)

return returnobj
end function

public function decimal getunitcost () throws closedownexception;decimal unitcost
oleObject result

result = httpget("/UnitCost")
unitcost = dec(result.Item("unitCost"))
result.DisconnectObject()
destroy result

return unitcost
end function

public function corpstate checkCorpNum(string corpNum) throws closedownexception;corpstate result
oleobject dic
string url

url = "/Check?CN="

if isnull(corpNum) or corpNum = "" then throw exception.setCodeNMessage(-99999999,"사업자번호가 입력되지 않았습니다.")

url += corpNum

dic = httpget(url)
result = tocorpstate(dic)

dic.DisconnectObject()
destroy dic

return result
end function

public subroutine checkCorpNums (ref string corpNumList[], ref corpstate ref_returnlist[]) throws closedownexception ;any dicList[]
oleobject infoDic
string postData
Integer i

if isnull(corpNumList) or upperbound(corpNumList) <= 0  then throw exception.setCodeNMessage(-99999999,"사업자번호 배열이 입력되지 않았습니다.")

postData ='['

for i = 1 to upperbound(corpNumList)
	postData += '"' + corpNumList[i] + '"'
	if i < upperbound(corpNumList) then postData += ','
next

postData +=']'

dicList = httppost("/Check", postData)

for i = 1 to upperbound(dicList)
	infoDic = dicList[i]
	ref_returnlist[i] = tocorpstate(infodic)
	
	infoDic.DisconnectObject()
	destroy infoDic
next

end subroutine

public function corpstate tocorpstate(ref oleobject dic);corpstate result

if Not(isNull(dic.Item("corpNum"))) then
	result.corpNum = string(dic.Item("corpNum"))
end if

if Not(isNull(dic.Item("type"))) then
	result.ctype = string(dic.Item("type"))
end if

if Not(isNull(dic.Item("state"))) then
	result.state = string(dic.Item("state"))
end if

if Not(isNull(dic.Item("stateDate"))) then
	result.stateDate = string(dic.Item("stateDate"))
end if

if Not(isNull(dic.Item("checkDate"))) then
	result.checkDate = string(dic.Item("checkDate"))
end if

return result
end function

on closedown.create
call super::create
TriggerEvent( this, "constructor" )
end on

on closedown.destroy
TriggerEvent( this, "destructor" )
call super::destroy
end on

event constructor;setnull(in_authority)
exception  = create closedownexception
scopes[1] = "170"
end event

