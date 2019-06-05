/*
Copyright (c) 2017-2019 Timur Gafarov

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

module dagon.render.shaders.sky;

import std.stdio;
import std.math;
import std.conv;

import dlib.core.memory;
import dlib.core.ownership;
import dlib.math.vector;
import dlib.math.matrix;
import dlib.image.color;

import dagon.core.bindings;
import dagon.graphics.state;
import dagon.graphics.shader;
import dagon.graphics.cubemap;

class SkyShader: Shader
{
    string vs = import("Sky.vert.glsl");
    string fs = import("Sky.frag.glsl");

    this(Owner owner)
    {
        auto myProgram = New!ShaderProgram(vs, fs, this);
        super(myProgram, owner);
    }

    override void bindParameters(GraphicsState* state)
    {
        auto idiffuse = "diffuse" in state.material.inputs;

        // Matrices
        setParameter("modelViewMatrix", state.modelViewMatrix);
        setParameter("projectionMatrix", state.projectionMatrix);
        setParameter("normalMatrix", state.normalMatrix);
        setParameter("viewMatrix", state.viewMatrix);
        setParameter("invViewMatrix", state.invViewMatrix);

        // Diffuse
        if (idiffuse.texture)
        {
            glActiveTexture(GL_TEXTURE4);

            auto cubemap = cast(Cubemap)idiffuse.texture;

            if (cubemap)
            {
                cubemap.bind();
                setParameter("envTextureCube", cast(int)4);
                setParameterSubroutine("environment", ShaderType.Fragment, "environmentCubemap");
            }
            else
            {
                idiffuse.texture.bind();
                setParameter("envTexture", cast(int)4);
                setParameterSubroutine("environment", ShaderType.Fragment, "environmentTexture");
            }
        }
        else
        {
            setParameter("envColor", idiffuse.asVector4f);
            setParameterSubroutine("environment", ShaderType.Fragment, "environmentColor");
        }

        glActiveTexture(GL_TEXTURE0);

        super.bindParameters(state);
    }

    override void unbindParameters(GraphicsState* state)
    {
        super.unbindParameters(state);

        glActiveTexture(GL_TEXTURE4);
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindTexture(GL_TEXTURE_CUBE_MAP, 0);

        glActiveTexture(GL_TEXTURE0);
    }
}
