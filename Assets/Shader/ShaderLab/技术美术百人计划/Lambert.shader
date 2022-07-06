Shader "技术美术百人计划/Lambert"
{
    Properties
    {
        [MainTexture] _BaseMap("主纹理",2D) = "white"
    }
    SubShader
    {
        Tags{
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
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
                float4 normal:NORMAL;
            };

            struct Varyings{
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normalWS : NORMAL;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert(Attributes input){
                Varyings o;
                o.positionCS = TransformObjectToHClip(input.position.xyz);
                o.normalWS = TransformObjectToWorldNormal(input.normal);

                o.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return o;
            }

            half4 frag(Varyings v):SV_TARGET{
                float3 normal = normalize(v.normalWS);
                Light mainLight = GetMainLight();
                half4 lightColor = real4(mainLight.color,1);
                float3 lightDir = normalize(mainLight.direction);

                half4 albedo = SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,v.uv);

                half4 diffuse = saturate(dot(lightDir,normal)*0.5 + 0.5);

                return albedo * lightColor * diffuse;
            }

            ENDHLSL
        }

    }
}
