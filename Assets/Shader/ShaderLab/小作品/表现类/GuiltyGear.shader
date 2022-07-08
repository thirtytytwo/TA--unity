Shader "Thirtytwo/GuiltyGear"
{
    Properties{
        [Space]
        [MainTexture]_BaseMap("主贴图",2D) = "white"{}
        _Diffuse("漫反射颜色",Color) = (1,1,1,1)
        [Space]
        _ShadowMap("阴影贴图",2D) = "white"{}
        _ShadowIntensity("阴影强度",Range(0,1)) = 0.7
        [Space]
        _DetailMap("磨损线条贴图",2D) = "white"{}
        _DetailIntensity("磨损强度",Range(0,1)) = 1
        [Space]
        _LightMap("光照贴图",2D) = "white"{}
        _RampOffset("Ramp偏移量",range(0,1)) = 0
        _LightTreshold("光照边缘范围",Range(0,1)) = 0.5
        [Space]
        _DecalMap("贴花",2D) = "white"{}
        [Space]
        _RimWidth("边缘光宽度",Range(0,1)) = 0.5
        _RimIntensity("边缘光强度",Range(0,1)) = 0.7
        [Space]
        _SpecularPower("高光粗糙度",Range(0,50)) = 15
        _SpecularIntensity("高光强度",Range(0,5)) = 1
        [Space]
        _MetallicStepSpecularWidth("金属的高光宽度",Range(0,1)) = 0.5
        _MetallicStepSpecularIntensity("金属的高光强度",Range(0,1)) = 0.8
        [Space]
        _LayerMaskStep("身体区域切分",Range(0,255)) = 35
        _BodySpecularWidth("身体区域高光宽度",Range(0,1)) = 0.5
        _BodySpecularIntensity("身体的高光强度",Range(0,1)) = 0.8
        [Space]
        [Toggle]_FACESHADOWTEX("启用脸部阴影图", float) = 0
        _HeadSpecularWidth("头部的高光宽度",Range(0,1)) = 0.5
        _HeadSpecularIntensity("头部的高光强度",Range(0,1)) = 0.8
        [Space]
        _OutlineWidth("描边大小",Range(0,1)) = 0.1
        _OutlineColor("描边颜色",Color) = (1,1,1,1)
    }

    SubShader{
        LOD 100

        //角色着色
        pass{
            Tags{
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
                "LightMode" = "ForwardBase"
            }
            ZWrite on
            Cull back

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _FACESHADOWTEX_ON
            #pragma multi_compile_fwdbase
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct Attributes{
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 vertexColor : COLOR;
                float2 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct Varyings{
                float4 pos : SV_POSITION;
                float3 worldNormal : NORMAL;
                float4 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float4 vertexColor : TEXCOORD2;
                float3 tangent : TEXCOORD3;
                float3 viewDir :TEXCOORD4;
                //LIGHTING_COORDS(4, 5)
            };

            //基础计算数据
            struct BaseCompute{
                half3 tangent;
                half3 normalDir;
                half3 lightDir;
                half4 lightColor;
                half3 viewDir;
                half3 h;
                half NdotL;
                half NdotL01;
                half NdotV;
                half NdotH;
            };

            //贴图数据集合
            struct TextureCollection{
                half4 baseMap;
                half4 lightMap;
                half4 detailMap;
                half4 shadowMap;
                half4 decalMap;
                float specularLayerMask;
                float rampOffsetMask;
                float specularIntensityMask;
                float innerLineMask;
                float shadowAOMask;
                float modelPart;
                float outlineIntensity;
            };
            //贴图采样
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            TEXTURE2D(_LightMap);
            SAMPLER(sampler_LightMap);
            TEXTURE2D(_DetailMap);
            SAMPLER(sampler_DetailMap);
            TEXTURE2D(_DecalMap);
            SAMPLER(sampler_DecalMap);
            TEXTURE2D(_ShadowMap);
            SAMPLER(sampler_ShadowMap);

            CBUFFER_START(UnityPerMaterial)
            half4 _BaseMap_ST;
            float4 _Diffuse;
            float _SpecularPower;
            float _SpecularIntensity;
            float _MetallicStepSpecularWidth;
            float _MetallicStepSpecularIntensity;
            float _LayerMaskStep;
            float _BodySpecularWidth;
            float _BodySpecularIntensity;
            float _HeadSpecularWidth;
            float _HeadSpecularIntensity;
            float _LightTreshold;
            float _RampOffset;
            float _DetailIntensity;
            float _ShadowIntensity;
            float _RimWidth;
            float _RimIntensity;
            TextureCollection texCol;
            BaseCompute baseData;
            CBUFFER_END

            //-------------基础数据处理-----------------
            void ComputeBaseData(Varyings v){
                baseData.tangent = normalize(v.tangent);
                baseData.normalDir = normalize(v.worldNormal);
                Light mainLight = GetMainLight();
                baseData.lightDir = normalize(mainLight.direction);
                baseData.lightColor = half4(mainLight.color,1);
                baseData.viewDir = normalize(v.viewDir);
                baseData.h = normalize(baseData.lightDir + baseData.viewDir);
                baseData.NdotL = dot(baseData.normalDir, baseData.lightDir);
                baseData.NdotL01 = baseData.NdotL * 0.5 + 0.5;
                baseData.NdotV = dot(baseData.normalDir,baseData.viewDir);
                baseData.NdotH = dot(baseData.normalDir, baseData.h);
            }
            //-----------贴图数据---------------
            void SampleBaseTexture(Varyings v)
            {
                texCol.baseMap               = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, v.uv);
                texCol.lightMap              = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, v.uv);
                texCol.detailMap             = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, v.uv.zw);
                texCol.shadowMap             = SAMPLE_TEXTURE2D(_ShadowMap, sampler_ShadowMap, v.uv);
                texCol.decalMap              = SAMPLE_TEXTURE2D(_DecalMap, sampler_DecalMap, v.uv);
                texCol.specularLayerMask     = texCol.lightMap.r;     //高光材质类型（通用、金属、皮革）
                texCol.rampOffsetMask        = texCol.lightMap.g;     //Ramp偏移值
                texCol.specularIntensityMask = texCol.lightMap.b;     //高光强度类型Mask（无高光、裁边高光、Blinn-Phong高光）
                texCol.innerLineMask         = texCol.lightMap.a;     //内勾线Mask
                texCol.shadowAOMask          = v.vertexColor.r;//AO常暗部分
                texCol.modelPart             = v.vertexColor.g;//用来区分身体的部位，比如脸部=88
                texCol.outlineIntensity      = v.vertexColor.b;//描边粗细
                                             // = v.vertexColor.a;//没用到的通道
            }
            //-----------漫反射--------------
            half3 Diffuse(float threshold){
                texCol.baseMap *= texCol.innerLineMask;
                texCol.baseMap = lerp(texCol.baseMap, texCol.baseMap * texCol.detailMap, _DetailIntensity);
                float3 diffuse = lerp(lerp(texCol.shadowMap,texCol.baseMap,(1 - -_ShadowIntensity)), texCol.baseMap,threshold);
                return diffuse * baseData.lightColor.rgb;
            }
            //----------------Rim-----------------
            half3 Rim(float threshold){
                float3 rim = step(1 - _RimWidth, (1 - baseData.NdotV)) * _RimIntensity * texCol.baseMap;
                rim = lerp(0,rim,threshold);
                rim *= baseData.lightColor.rgb;
                return rim;
            }
            //------------高光和边缘光--------------
            half3 Specular(){
                float3 specular = 0;
                specular = pow(saturate(baseData.NdotH),_SpecularPower) * _SpecularIntensity;
                specular = max(0, specular);
                // [0,10] 普通 无边缘光  
                // (10,145]皮革 皮肤 有边缘光
                // (145,200] 头发 有边缘光
                // (200,255] 金属 裁剪高光 无边缘光
                float linearMask = pow(texCol.specularLayerMask,1 / 2.2);//2.2是伽马校正值，1除校正值是校正回线性空间,颜色到物理值
                float layerMask = linearMask * 255;
                if(layerMask >= 10 && layerMask < _LayerMaskStep){
                    float specularIntensity = pow(texCol.specularIntensityMask, 1/ 2.2) * 255;
                    float stepSpecularMask = float(specularIntensity > 0 && specularIntensity <= 140);
                    float3 bodySpecular = saturate(step(1 - baseData.NdotV, _BodySpecularWidth)) * _BodySpecularIntensity * texCol.baseMap;
                    specular = lerp(specular, bodySpecular, stepSpecularMask);
                }
                if(layerMask > 145 && layerMask <= 200){
                    float specularIntensity = pow(texCol.specularIntensityMask, 1/ 2.2);
                    float stepSpecularMask = float(specularIntensity > 140 && specularIntensity <= 255);
                    float3 hairSpecular = saturate(step(1 - _HeadSpecularWidth, baseData.NdotV)) * _HeadSpecularIntensity * texCol.baseMap * stepSpecularMask;
                    specular = lerp(specular, hairSpecular, stepSpecularMask);
                }
                if(layerMask > 200 )
                {
                    float3 metallicStepSpecular = step(baseData.NdotL01, _MetallicStepSpecularWidth) * _MetallicStepSpecularIntensity * texCol.baseMap;
                    specular += metallicStepSpecular;
                }
                return specular;
            }
            Varyings vert(Attributes i){
                Varyings o;
                const VertexPositionInputs input = GetVertexPositionInputs(i.vertex.xyz);
                const VertexNormalInputs normalInput = GetVertexNormalInputs(i.normal,i.tangent);
                o.pos = input.positionCS;
                o.worldPos = input.positionWS;
                o.viewDir = normalize(GetCameraPositionWS() - o.worldPos);
                o.worldNormal = normalInput.normalWS;
                o.tangent = normalInput.tangentWS;
                o.vertexColor = i.vertexColor;
                o.uv.xy = TRANSFORM_TEX(i.uv,_BaseMap);
                o.uv.zw = i.uv2;
                //TRANSFER_VERTEX_TO_FRAGMENT(o);
                return o;
            }
            half4 frag(Varyings i):SV_TARGET{
                ComputeBaseData(i);
                SampleBaseTexture(i);

                float threshold = saturate(step(_LightTreshold,(baseData.NdotL01 + _RampOffset + texCol.rampOffsetMask) * texCol.shadowAOMask));
                float3 diffuse = Diffuse(threshold);
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * texCol.baseMap;

                #ifdef _FACESHADOWTEX_ON
                if(texCol.modelPart >= 0.22 && texCol.modelPart < 0.26){
                    diffuse = Diffuse(threshold);
                    return half4(diffuse + ambient, 1.0);
                }
                #endif

                float3 rim = Rim(threshold);
                float3 specular = Specular();

                half3 color = diffuse + rim + specular + ambient;
                return half4(color,1);
            }
            ENDHLSL
        }
    }
}
