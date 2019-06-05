/*
Copyright (c) 2019 Timur Gafarov

Boost Software License - Version 1.0 - August 17th, 2003
Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dagon.graphics.state;

import dlib.math.vector;
import dlib.math.matrix;

import dagon.core.bindings;
import dagon.graphics.material;
import dagon.graphics.shader;
import dagon.graphics.environment;
import dagon.graphics.light;

struct GraphicsState
{
    int layer;

    Vector2f resolution;
    float zNear;
    float zFar;

    Vector3f cameraPosition;

    Matrix4x4f modelMatrix;
    Matrix4x4f invModelMatrix;

    Matrix4x4f viewMatrix;
    Matrix4x4f invViewMatrix;

    Matrix4x4f projectionMatrix;
    Matrix4x4f invProjectionMatrix;

    Matrix4x4f modelViewMatrix;
    Matrix4x4f normalMatrix;

    Material material;
    //Shader overrideShader;
    Environment environment;
    Light light;

    bool colorMask;
    bool depthMask;

    bool culling;

    GLuint colorTexture;
    GLuint depthTexture;
    GLuint normalTexture;
    GLuint pbrTexture;
    GLuint occlusionTexture;

    void reset()
    {
        layer = 1;

        resolution = Vector2f(0.0f, 0.0f);
        zNear = 0.0f;
        zFar = 0.0f;

        cameraPosition = Vector3f(0.0f, 0.0f, 0.0f);

        modelMatrix = Matrix4x4f.identity;
        invModelMatrix = Matrix4x4f.identity;

        viewMatrix = Matrix4x4f.identity;
        invViewMatrix = Matrix4x4f.identity;

        projectionMatrix = Matrix4x4f.identity;
        invProjectionMatrix = Matrix4x4f.identity;

        modelViewMatrix = Matrix4x4f.identity;
        normalMatrix = Matrix4x4f.identity;

        material = null;
        //overrideShader = null;
        environment = null;
        light = null;

        colorMask = true;
        depthMask = true;

        culling = true;

        colorTexture = 0;
        depthTexture = 0;
        normalTexture = 0;
        pbrTexture = 0;
        occlusionTexture = 0;
    }
}
