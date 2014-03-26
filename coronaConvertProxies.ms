/* 
Version: v0.02
Written by Pavel Vojacek
codepoint.eu
license MIT
Copyright (c) 2014 Pavel Vojacek

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/

fn coronaConvertProxiesDialog = (
::createCoronaMtl
rollout coronaProxyConverterRL "corona Proxy converter"
(
local outdir	
	
timer tmcheckconv interval:1000 active:false

checkbox cbConvertMats "Convert materials" checked:true
label lblWarn1 "For material conversion"
label lblWarn2 "run coronaConverter first"


group "VRP import options" (
	checkbox cbWeldVerts "Weld vertices in result"
	checkbox cbExpNorm "Use explicit normals"
	)	
	
checkbox cbcache "Cache In RAM" checked:false	
	group "Output Folder" (
		button btnSelDir "Same as original" width:140
	)
	
group "Viewport visualization:"
	(
	dropdownlist ddlPreviz "Method" items:#("Solid BB", "Wire BB","Point cloud","Full mesh") selection:3
	spinner spnPCD "Point Cloud %" range:[0,100,2]
	)
checkbox cbSelOnly "Selection only"	
button btnAction "Convert" width:155 height:30

function checkconv = (
	if createCoronaMtl==undefined then (
		cbConvertMats.enabled = false	
		cbConvertMats.checked = false
		tmcheckconv.active = true
		)
	else (
		cbConvertMats.enabled = true
		cbConvertMats.checked = true
		lblWarn1.visible = false
		lblWarn2.visible = false
		tmcheckconv.active = false
		)
	)
	
fn convertVRPtoCP obj =	(
	if classof obj==vrayproxy then (
		ExpNorm = if cbExpNorm.checked then 1 else 0
		WeldVerts = if cbWeldVerts.checked then 1 else 0
		mmesh = vrayMeshImport proxy:obj explicitNormals:ExpNorm  weldVertices:WeldVerts
		cfilename = (if outdir==undefined then getfilenamepath obj.filename else outdir)+ "\\" + getfilenamefile obj.filename + ".cbin"
		cproxy = CoronaProxy cacheInRam:cbcache.checked previzType:(ddlPreviz.selection-1) displayVertexFraction:spnPCD.value
		CoronaProxy.ProxyFp.fromScene cproxy mmesh[1] cfilename		
		delete mmesh
		cproxy
		)	
	)
	
fn convertScene = (
	for o in geometry where classof o == vrayproxy and (not cbSelOnly.checked or o.isselected)do
		(
			InstanceMgr.GetInstances o &instances			
			cpr = convertVRPtoCP o
			if cbConvertMats.checked then (
				newmat = createCoronaMtl o.material			
				cpr.material = newmat
			)
			replaceInstances o cpr
			delete cpr
			)
	)

 on btnAction pressed do (
	undo "corona Proxy conversion" on convertscene()
	)	

on coronaProxyConverterRL open do (
	checkconv()
	)	

on tmcheckconv tick do (
	checkconv()
	)	

on btnSelDir pressed do (
	outdir = getSavePath caption:"Corona Proxy Output Folder"
	if outdir!=undefined then btnSelDir.caption = outdir else btnSelDir.caption = "Same as original" 
	)
)

createDialog coronaProxyConverterRL
)
coronaConvertProxiesDialog()