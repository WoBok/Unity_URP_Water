using UnityEditor;
using UnityEngine;

public class CreateShaderTemplate : Editor
{
    [MenuItem("Assets/Create/Shader/URP Shader", false, 0)]
    static void CreateURPShaderFile()
    {
        var templatePath = Application.dataPath + "/Editor/CreateShaderTemplate/ShaderTemplates/URPShader.txt";
        CreateShaderFile(templatePath, "New URP Shader.shader");
    }
    [MenuItem("Assets/Create/Shader/URP PBR Shader", false, 0)]
    static void CreateURPPBRShaderFile()
    {
        var templatePath = Application.dataPath + "/Editor/CreateShaderTemplate/ShaderTemplates/URP_PBR_Shader.txt";
        CreateShaderFile(templatePath, "New URP PBR Shader.shader");
    }
    static void CreateShaderFile(string filePath, string defaultNewFileName)
    {
        ProjectWindowUtil.StartNameEditingIfProjectWindowExists(
            0,
            CreateInstance<DoCreateShaderScritpAsset>(),
            defaultNewFileName,
            null,
            filePath
            );
    }
}