Shader "Thirtytwo/GuiltyGear"
{
    Properties{
        [MainTexture]_BaseMap("base map",2D) = "white"{}
        _DecalMap("decal map",2D) = "white"{}
        _DetailMap("detail map",2D) = "white"{}
        _LimMap("lim map",2D) = "white"{}
        _SssMap("sss map",2D) = "white"{}

        _Glossy("高光指数", Range(0,255)) = 1
    }
    SubShader{
        Tags{
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        pass{
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes{
                float4 position:POSITION;
                float2 uv:TEXCOORD0;
                float3 normal : NORMAL;
                half4 color:COLOR;
            };

            struct Varyings{
                float4 positionCS:SV_POSITION;
                float3 positionWS:POSITION_WS;
                float2 uv: TEXCOORD0;
                float3 normalWS:NORMAL_WS;
                half4 vertexcolor : COLOR;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            TEXTURE2D(_LimMap);
            SAMPLER(sampler_LimMap);

            TEXTURE2D(_SssMap);
            SAMPLER(sampler_SssMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _LimMap_ST;
                float4 _SssMap_ST;
                float _Glossy;
            CBUFFER_END

            Varyings vert(Attributes i){
                const VertexPositionInputs positionInputs = GetVertexPositionInputs(i.position.xyz);
                Varyings o;
                o.positionCS = positionInputs.positionCS;
                o.positionWS = positionInputs.positionWS;
                o.normalWS = TransformObjectToWorldNormal(i.normal);
                o.uv = TRANSFORM_TEX(i.uv,_BaseMap);
                o.vertexcolor = i.color;
                return o;
            }
            half4 frag(Varyings v):SV_TARGET{
                //采样
                half4 base = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,v.uv);
                half4 light = SAMPLE_TEXTURE2D(_LimMap,sampler_LimMap,v.uv);
                half4 shadow = SAMPLE_TEXTURE2D(_SssMap,sampler_SssMap,v.uv);
                //参数设置
                //贴图参数
                half lineColor = light.a;
                half shadowThreshold = light.g;
                half ao = v.vertexcolor.r;
                //漫反射参数
                float3 normal = normalize(v.normalWS);
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                //漫反射
                half NdotL = dot(normal,lightDir);
                half half_Lambert = NdotL * 0.5 + 0.5;
                half toon_Diffuse = saturate((half_Lambert * ao + shadowThreshold));
                half3 final_Diffuse = lerp(shadow.rgb,base.rgb,toon_Diffuse);
                return half4(final_Diffuse,1);
                //高光

            }
            ENDHLSL
        }
    }
}
