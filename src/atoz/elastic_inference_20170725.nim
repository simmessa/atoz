
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Elastic  Inference
## version: 2017-07-25
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## Elastic Inference public APIs.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/elastic-inference/
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

  OpenApiRestCall_612649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612649): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "api.elastic-inference.ap-northeast-1.amazonaws.com", "ap-southeast-1": "api.elastic-inference.ap-southeast-1.amazonaws.com", "us-west-2": "api.elastic-inference.us-west-2.amazonaws.com", "eu-west-2": "api.elastic-inference.eu-west-2.amazonaws.com", "ap-northeast-3": "api.elastic-inference.ap-northeast-3.amazonaws.com", "eu-central-1": "api.elastic-inference.eu-central-1.amazonaws.com", "us-east-2": "api.elastic-inference.us-east-2.amazonaws.com", "us-east-1": "api.elastic-inference.us-east-1.amazonaws.com", "cn-northwest-1": "api.elastic-inference.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "api.elastic-inference.ap-south-1.amazonaws.com", "eu-north-1": "api.elastic-inference.eu-north-1.amazonaws.com", "ap-northeast-2": "api.elastic-inference.ap-northeast-2.amazonaws.com", "us-west-1": "api.elastic-inference.us-west-1.amazonaws.com", "us-gov-east-1": "api.elastic-inference.us-gov-east-1.amazonaws.com", "eu-west-3": "api.elastic-inference.eu-west-3.amazonaws.com", "cn-north-1": "api.elastic-inference.cn-north-1.amazonaws.com.cn", "sa-east-1": "api.elastic-inference.sa-east-1.amazonaws.com", "eu-west-1": "api.elastic-inference.eu-west-1.amazonaws.com", "us-gov-west-1": "api.elastic-inference.us-gov-west-1.amazonaws.com", "ap-southeast-2": "api.elastic-inference.ap-southeast-2.amazonaws.com", "ca-central-1": "api.elastic-inference.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "api.elastic-inference.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "api.elastic-inference.ap-southeast-1.amazonaws.com",
      "us-west-2": "api.elastic-inference.us-west-2.amazonaws.com",
      "eu-west-2": "api.elastic-inference.eu-west-2.amazonaws.com",
      "ap-northeast-3": "api.elastic-inference.ap-northeast-3.amazonaws.com",
      "eu-central-1": "api.elastic-inference.eu-central-1.amazonaws.com",
      "us-east-2": "api.elastic-inference.us-east-2.amazonaws.com",
      "us-east-1": "api.elastic-inference.us-east-1.amazonaws.com", "cn-northwest-1": "api.elastic-inference.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "api.elastic-inference.ap-south-1.amazonaws.com",
      "eu-north-1": "api.elastic-inference.eu-north-1.amazonaws.com",
      "ap-northeast-2": "api.elastic-inference.ap-northeast-2.amazonaws.com",
      "us-west-1": "api.elastic-inference.us-west-1.amazonaws.com",
      "us-gov-east-1": "api.elastic-inference.us-gov-east-1.amazonaws.com",
      "eu-west-3": "api.elastic-inference.eu-west-3.amazonaws.com",
      "cn-north-1": "api.elastic-inference.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "api.elastic-inference.sa-east-1.amazonaws.com",
      "eu-west-1": "api.elastic-inference.eu-west-1.amazonaws.com",
      "us-gov-west-1": "api.elastic-inference.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "api.elastic-inference.ap-southeast-2.amazonaws.com",
      "ca-central-1": "api.elastic-inference.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "elastic-inference"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_TagResource_613257 = ref object of OpenApiRestCall_612649
proc url_TagResource_613259(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_613258(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613260 = path.getOrDefault("resourceArn")
  valid_613260 = validateParameter(valid_613260, JString, required = true,
                                 default = nil)
  if valid_613260 != nil:
    section.add "resourceArn", valid_613260
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613261 = header.getOrDefault("X-Amz-Signature")
  valid_613261 = validateParameter(valid_613261, JString, required = false,
                                 default = nil)
  if valid_613261 != nil:
    section.add "X-Amz-Signature", valid_613261
  var valid_613262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613262 = validateParameter(valid_613262, JString, required = false,
                                 default = nil)
  if valid_613262 != nil:
    section.add "X-Amz-Content-Sha256", valid_613262
  var valid_613263 = header.getOrDefault("X-Amz-Date")
  valid_613263 = validateParameter(valid_613263, JString, required = false,
                                 default = nil)
  if valid_613263 != nil:
    section.add "X-Amz-Date", valid_613263
  var valid_613264 = header.getOrDefault("X-Amz-Credential")
  valid_613264 = validateParameter(valid_613264, JString, required = false,
                                 default = nil)
  if valid_613264 != nil:
    section.add "X-Amz-Credential", valid_613264
  var valid_613265 = header.getOrDefault("X-Amz-Security-Token")
  valid_613265 = validateParameter(valid_613265, JString, required = false,
                                 default = nil)
  if valid_613265 != nil:
    section.add "X-Amz-Security-Token", valid_613265
  var valid_613266 = header.getOrDefault("X-Amz-Algorithm")
  valid_613266 = validateParameter(valid_613266, JString, required = false,
                                 default = nil)
  if valid_613266 != nil:
    section.add "X-Amz-Algorithm", valid_613266
  var valid_613267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613267 = validateParameter(valid_613267, JString, required = false,
                                 default = nil)
  if valid_613267 != nil:
    section.add "X-Amz-SignedHeaders", valid_613267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613269: Call_TagResource_613257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ## 
  let valid = call_613269.validator(path, query, header, formData, body)
  let scheme = call_613269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613269.url(scheme.get, call_613269.host, call_613269.base,
                         call_613269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613269, url, valid)

proc call*(call_613270: Call_TagResource_613257; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ## Adds the specified tag(s) to an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to tag.
  ##   body: JObject (required)
  var path_613271 = newJObject()
  var body_613272 = newJObject()
  add(path_613271, "resourceArn", newJString(resourceArn))
  if body != nil:
    body_613272 = body
  result = call_613270.call(path_613271, nil, nil, nil, body_613272)

var tagResource* = Call_TagResource_613257(name: "tagResource",
                                        meth: HttpMethod.HttpPost, host: "api.elastic-inference.amazonaws.com",
                                        route: "/tags/{resourceArn}",
                                        validator: validate_TagResource_613258,
                                        base: "/", url: url_TagResource_613259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_612987 = ref object of OpenApiRestCall_612649
proc url_ListTagsForResource_612989(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_612988(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613115 = path.getOrDefault("resourceArn")
  valid_613115 = validateParameter(valid_613115, JString, required = true,
                                 default = nil)
  if valid_613115 != nil:
    section.add "resourceArn", valid_613115
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613116 = header.getOrDefault("X-Amz-Signature")
  valid_613116 = validateParameter(valid_613116, JString, required = false,
                                 default = nil)
  if valid_613116 != nil:
    section.add "X-Amz-Signature", valid_613116
  var valid_613117 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613117 = validateParameter(valid_613117, JString, required = false,
                                 default = nil)
  if valid_613117 != nil:
    section.add "X-Amz-Content-Sha256", valid_613117
  var valid_613118 = header.getOrDefault("X-Amz-Date")
  valid_613118 = validateParameter(valid_613118, JString, required = false,
                                 default = nil)
  if valid_613118 != nil:
    section.add "X-Amz-Date", valid_613118
  var valid_613119 = header.getOrDefault("X-Amz-Credential")
  valid_613119 = validateParameter(valid_613119, JString, required = false,
                                 default = nil)
  if valid_613119 != nil:
    section.add "X-Amz-Credential", valid_613119
  var valid_613120 = header.getOrDefault("X-Amz-Security-Token")
  valid_613120 = validateParameter(valid_613120, JString, required = false,
                                 default = nil)
  if valid_613120 != nil:
    section.add "X-Amz-Security-Token", valid_613120
  var valid_613121 = header.getOrDefault("X-Amz-Algorithm")
  valid_613121 = validateParameter(valid_613121, JString, required = false,
                                 default = nil)
  if valid_613121 != nil:
    section.add "X-Amz-Algorithm", valid_613121
  var valid_613122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613122 = validateParameter(valid_613122, JString, required = false,
                                 default = nil)
  if valid_613122 != nil:
    section.add "X-Amz-SignedHeaders", valid_613122
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613145: Call_ListTagsForResource_612987; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns all tags of an Elastic Inference Accelerator.
  ## 
  let valid = call_613145.validator(path, query, header, formData, body)
  let scheme = call_613145.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613145.url(scheme.get, call_613145.host, call_613145.base,
                         call_613145.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613145, url, valid)

proc call*(call_613216: Call_ListTagsForResource_612987; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Returns all tags of an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to list the tags for.
  var path_613217 = newJObject()
  add(path_613217, "resourceArn", newJString(resourceArn))
  result = call_613216.call(path_613217, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_612987(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "api.elastic-inference.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_612988, base: "/",
    url: url_ListTagsForResource_612989, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_613273 = ref object of OpenApiRestCall_612649
proc url_UntagResource_613275(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resourceArn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_613274(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resourceArn` field"
  var valid_613276 = path.getOrDefault("resourceArn")
  valid_613276 = validateParameter(valid_613276, JString, required = true,
                                 default = nil)
  if valid_613276 != nil:
    section.add "resourceArn", valid_613276
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613277 = query.getOrDefault("tagKeys")
  valid_613277 = validateParameter(valid_613277, JArray, required = true, default = nil)
  if valid_613277 != nil:
    section.add "tagKeys", valid_613277
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_613278 = header.getOrDefault("X-Amz-Signature")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Signature", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Content-Sha256", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Date")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Date", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-Credential")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-Credential", valid_613281
  var valid_613282 = header.getOrDefault("X-Amz-Security-Token")
  valid_613282 = validateParameter(valid_613282, JString, required = false,
                                 default = nil)
  if valid_613282 != nil:
    section.add "X-Amz-Security-Token", valid_613282
  var valid_613283 = header.getOrDefault("X-Amz-Algorithm")
  valid_613283 = validateParameter(valid_613283, JString, required = false,
                                 default = nil)
  if valid_613283 != nil:
    section.add "X-Amz-Algorithm", valid_613283
  var valid_613284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613284 = validateParameter(valid_613284, JString, required = false,
                                 default = nil)
  if valid_613284 != nil:
    section.add "X-Amz-SignedHeaders", valid_613284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613285: Call_UntagResource_613273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ## 
  let valid = call_613285.validator(path, query, header, formData, body)
  let scheme = call_613285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613285.url(scheme.get, call_613285.host, call_613285.base,
                         call_613285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613285, url, valid)

proc call*(call_613286: Call_UntagResource_613273; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ## Removes the specified tag(s) from an Elastic Inference Accelerator.
  ##   resourceArn: string (required)
  ##              : The ARN of the Elastic Inference Accelerator to untag.
  ##   tagKeys: JArray (required)
  ##          : The list of tags to remove from the Elastic Inference Accelerator.
  var path_613287 = newJObject()
  var query_613288 = newJObject()
  add(path_613287, "resourceArn", newJString(resourceArn))
  if tagKeys != nil:
    query_613288.add "tagKeys", tagKeys
  result = call_613286.call(path_613287, query_613288, nil, nil, nil)

var untagResource* = Call_UntagResource_613273(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "api.elastic-inference.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_613274,
    base: "/", url: url_UntagResource_613275, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
