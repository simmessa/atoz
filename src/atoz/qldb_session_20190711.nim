
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon QLDB Session
## version: 2019-07-11
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## The transactional data APIs for Amazon QLDB
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/qldb/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "session.qldb.ap-northeast-1.amazonaws.com", "ap-southeast-1": "session.qldb.ap-southeast-1.amazonaws.com",
                           "us-west-2": "session.qldb.us-west-2.amazonaws.com",
                           "eu-west-2": "session.qldb.eu-west-2.amazonaws.com", "ap-northeast-3": "session.qldb.ap-northeast-3.amazonaws.com", "eu-central-1": "session.qldb.eu-central-1.amazonaws.com",
                           "us-east-2": "session.qldb.us-east-2.amazonaws.com",
                           "us-east-1": "session.qldb.us-east-1.amazonaws.com", "cn-northwest-1": "session.qldb.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "session.qldb.ap-south-1.amazonaws.com", "eu-north-1": "session.qldb.eu-north-1.amazonaws.com", "ap-northeast-2": "session.qldb.ap-northeast-2.amazonaws.com",
                           "us-west-1": "session.qldb.us-west-1.amazonaws.com", "us-gov-east-1": "session.qldb.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "session.qldb.eu-west-3.amazonaws.com", "cn-north-1": "session.qldb.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "session.qldb.sa-east-1.amazonaws.com",
                           "eu-west-1": "session.qldb.eu-west-1.amazonaws.com", "us-gov-west-1": "session.qldb.us-gov-west-1.amazonaws.com", "ap-southeast-2": "session.qldb.ap-southeast-2.amazonaws.com", "ca-central-1": "session.qldb.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "session.qldb.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "session.qldb.ap-southeast-1.amazonaws.com",
      "us-west-2": "session.qldb.us-west-2.amazonaws.com",
      "eu-west-2": "session.qldb.eu-west-2.amazonaws.com",
      "ap-northeast-3": "session.qldb.ap-northeast-3.amazonaws.com",
      "eu-central-1": "session.qldb.eu-central-1.amazonaws.com",
      "us-east-2": "session.qldb.us-east-2.amazonaws.com",
      "us-east-1": "session.qldb.us-east-1.amazonaws.com",
      "cn-northwest-1": "session.qldb.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "session.qldb.ap-south-1.amazonaws.com",
      "eu-north-1": "session.qldb.eu-north-1.amazonaws.com",
      "ap-northeast-2": "session.qldb.ap-northeast-2.amazonaws.com",
      "us-west-1": "session.qldb.us-west-1.amazonaws.com",
      "us-gov-east-1": "session.qldb.us-gov-east-1.amazonaws.com",
      "eu-west-3": "session.qldb.eu-west-3.amazonaws.com",
      "cn-north-1": "session.qldb.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "session.qldb.sa-east-1.amazonaws.com",
      "eu-west-1": "session.qldb.eu-west-1.amazonaws.com",
      "us-gov-west-1": "session.qldb.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "session.qldb.ap-southeast-2.amazonaws.com",
      "ca-central-1": "session.qldb.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "qldb-session"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_SendCommand_601718 = ref object of OpenApiRestCall_601380
proc url_SendCommand_601720(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendCommand_601719(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Sends a command to an Amazon QLDB ledger.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  assert header != nil,
        "header argument is necessary due to required `X-Amz-Target` field"
  var valid_601845 = header.getOrDefault("X-Amz-Target")
  valid_601845 = validateParameter(valid_601845, JString, required = true, default = newJString(
      "QLDBSession.SendCommand"))
  if valid_601845 != nil:
    section.add "X-Amz-Target", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Signature")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Signature", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Content-Sha256", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Date")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Date", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Credential")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Credential", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Security-Token")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Security-Token", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-Algorithm")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-Algorithm", valid_601851
  var valid_601852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601852 = validateParameter(valid_601852, JString, required = false,
                                 default = nil)
  if valid_601852 != nil:
    section.add "X-Amz-SignedHeaders", valid_601852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601876: Call_SendCommand_601718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Sends a command to an Amazon QLDB ledger.
  ## 
  let valid = call_601876.validator(path, query, header, formData, body)
  let scheme = call_601876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601876.url(scheme.get, call_601876.host, call_601876.base,
                         call_601876.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601876, url, valid)

proc call*(call_601947: Call_SendCommand_601718; body: JsonNode): Recallable =
  ## sendCommand
  ## Sends a command to an Amazon QLDB ledger.
  ##   body: JObject (required)
  var body_601948 = newJObject()
  if body != nil:
    body_601948 = body
  result = call_601947.call(nil, nil, nil, nil, body_601948)

var sendCommand* = Call_SendCommand_601718(name: "sendCommand",
                                        meth: HttpMethod.HttpPost,
                                        host: "session.qldb.amazonaws.com", route: "/#X-Amz-Target=QLDBSession.SendCommand",
                                        validator: validate_SendCommand_601719,
                                        base: "/", url: url_SendCommand_601720,
                                        schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
