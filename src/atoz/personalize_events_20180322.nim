
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Personalize Events
## version: 2018-03-22
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <p/>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/personalize-events/
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

  OpenApiRestCall_593424 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593424](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593424): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "personalize-events.ap-northeast-1.amazonaws.com", "ap-southeast-1": "personalize-events.ap-southeast-1.amazonaws.com", "us-west-2": "personalize-events.us-west-2.amazonaws.com", "eu-west-2": "personalize-events.eu-west-2.amazonaws.com", "ap-northeast-3": "personalize-events.ap-northeast-3.amazonaws.com", "eu-central-1": "personalize-events.eu-central-1.amazonaws.com", "us-east-2": "personalize-events.us-east-2.amazonaws.com", "us-east-1": "personalize-events.us-east-1.amazonaws.com", "cn-northwest-1": "personalize-events.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "personalize-events.ap-south-1.amazonaws.com", "eu-north-1": "personalize-events.eu-north-1.amazonaws.com", "ap-northeast-2": "personalize-events.ap-northeast-2.amazonaws.com", "us-west-1": "personalize-events.us-west-1.amazonaws.com", "us-gov-east-1": "personalize-events.us-gov-east-1.amazonaws.com", "eu-west-3": "personalize-events.eu-west-3.amazonaws.com", "cn-north-1": "personalize-events.cn-north-1.amazonaws.com.cn", "sa-east-1": "personalize-events.sa-east-1.amazonaws.com", "eu-west-1": "personalize-events.eu-west-1.amazonaws.com", "us-gov-west-1": "personalize-events.us-gov-west-1.amazonaws.com", "ap-southeast-2": "personalize-events.ap-southeast-2.amazonaws.com", "ca-central-1": "personalize-events.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "personalize-events.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "personalize-events.ap-southeast-1.amazonaws.com",
      "us-west-2": "personalize-events.us-west-2.amazonaws.com",
      "eu-west-2": "personalize-events.eu-west-2.amazonaws.com",
      "ap-northeast-3": "personalize-events.ap-northeast-3.amazonaws.com",
      "eu-central-1": "personalize-events.eu-central-1.amazonaws.com",
      "us-east-2": "personalize-events.us-east-2.amazonaws.com",
      "us-east-1": "personalize-events.us-east-1.amazonaws.com",
      "cn-northwest-1": "personalize-events.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "personalize-events.ap-south-1.amazonaws.com",
      "eu-north-1": "personalize-events.eu-north-1.amazonaws.com",
      "ap-northeast-2": "personalize-events.ap-northeast-2.amazonaws.com",
      "us-west-1": "personalize-events.us-west-1.amazonaws.com",
      "us-gov-east-1": "personalize-events.us-gov-east-1.amazonaws.com",
      "eu-west-3": "personalize-events.eu-west-3.amazonaws.com",
      "cn-north-1": "personalize-events.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "personalize-events.sa-east-1.amazonaws.com",
      "eu-west-1": "personalize-events.eu-west-1.amazonaws.com",
      "us-gov-west-1": "personalize-events.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "personalize-events.ap-southeast-2.amazonaws.com",
      "ca-central-1": "personalize-events.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "personalize-events"
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PutEvents_593761 = ref object of OpenApiRestCall_593424
proc url_PutEvents_593763(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_PutEvents_593762(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Records user interaction event data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_593875 = header.getOrDefault("X-Amz-Date")
  valid_593875 = validateParameter(valid_593875, JString, required = false,
                                 default = nil)
  if valid_593875 != nil:
    section.add "X-Amz-Date", valid_593875
  var valid_593876 = header.getOrDefault("X-Amz-Security-Token")
  valid_593876 = validateParameter(valid_593876, JString, required = false,
                                 default = nil)
  if valid_593876 != nil:
    section.add "X-Amz-Security-Token", valid_593876
  var valid_593877 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593877 = validateParameter(valid_593877, JString, required = false,
                                 default = nil)
  if valid_593877 != nil:
    section.add "X-Amz-Content-Sha256", valid_593877
  var valid_593878 = header.getOrDefault("X-Amz-Algorithm")
  valid_593878 = validateParameter(valid_593878, JString, required = false,
                                 default = nil)
  if valid_593878 != nil:
    section.add "X-Amz-Algorithm", valid_593878
  var valid_593879 = header.getOrDefault("X-Amz-Signature")
  valid_593879 = validateParameter(valid_593879, JString, required = false,
                                 default = nil)
  if valid_593879 != nil:
    section.add "X-Amz-Signature", valid_593879
  var valid_593880 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593880 = validateParameter(valid_593880, JString, required = false,
                                 default = nil)
  if valid_593880 != nil:
    section.add "X-Amz-SignedHeaders", valid_593880
  var valid_593881 = header.getOrDefault("X-Amz-Credential")
  valid_593881 = validateParameter(valid_593881, JString, required = false,
                                 default = nil)
  if valid_593881 != nil:
    section.add "X-Amz-Credential", valid_593881
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593905: Call_PutEvents_593761; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Records user interaction event data.
  ## 
  let valid = call_593905.validator(path, query, header, formData, body)
  let scheme = call_593905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593905.url(scheme.get, call_593905.host, call_593905.base,
                         call_593905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593905, url, valid)

proc call*(call_593976: Call_PutEvents_593761; body: JsonNode): Recallable =
  ## putEvents
  ## Records user interaction event data.
  ##   body: JObject (required)
  var body_593977 = newJObject()
  if body != nil:
    body_593977 = body
  result = call_593976.call(nil, nil, nil, nil, body_593977)

var putEvents* = Call_PutEvents_593761(name: "putEvents", meth: HttpMethod.HttpPost,
                                    host: "personalize-events.amazonaws.com",
                                    route: "/events",
                                    validator: validate_PutEvents_593762,
                                    base: "/", url: url_PutEvents_593763,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
