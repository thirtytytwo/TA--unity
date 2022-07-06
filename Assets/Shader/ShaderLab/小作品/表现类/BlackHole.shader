Shader "Thirtytwo/Black Hole"
{
    Properties
    {
        [MainTexture]_BaseMap("base map", 2D) = "white"{}
        _RightX("right x",float) = 0
        _LeftX("left x", float) = 0
        _Control("control", Range(0, 2)) = 0
        _BlackHolePos("black hole position", Vector) = (1,1,1,1)
    }
    SubShader
    {
        Tags {
                "RenderPipeline" = "UniversalPipeline"
                "RenderType"="Opaque" 
            }
        LOD 100
        Cull off

        pass{
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes{
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varyings{
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float _RightX;
            float _LeftX;
            float _Control;
            float4 _BlackHolePos;
            CBUFFER_END

            float GetNormalizedDist(float worldPosX){
                float range = _RightX - _LeftX;
                float border = _RightX;
                float dist = abs(worldPosX - border);//获得当前点和边界的距离值
                float normalizedDist = saturate(dist/range);//对距离值进行归一化得到系数
                return normalizedDist;
            }
            Varyings vert(Attributes i){
                Varyings o;
                float3 worldPos = mul(unity_ObjectToWorld,i.position).xyz;
                float3 toBlackHole = mul(unity_WorldToObject,(_BlackHolePos - worldPos)).xyz;
                float normalizedDist = GetNormalizedDist(worldPos.x);
                float val = max(0,_Control - normalizedDist);//最左边的偏移值是1，所以我们要让control最大值为2能够移动最左边的顶点
                i.position.xyz += toBlackHole * val;

                o.uv = TRANSFORM_TEX(i.uv,_BaseMap);
                o.worldPos = worldPos;
                o.position = TransformObjectToHClip(i.position);
                return o;
            }

            half4 frag(Varyings v):SV_TARGET{
                if(_Control == 2){
                    clip(_BlackHolePos.x - v.worldPos.x);
                    clip(_BlackHolePos.y - v.worldPos.y);
                    clip(_BlackHolePos.z - v.worldPos.z);
                }
                return half4(SAMPLE_TEXTURE2D(_BaseMap,sampler_BaseMap,v.uv));
            }
            ENDHLSL
        }
    }
}
