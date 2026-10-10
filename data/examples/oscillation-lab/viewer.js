(()=>{var cy=Object.create;var Zp=Object.defineProperty;var fy=Object.getOwnPropertyDescriptor;var hy=Object.getOwnPropertyNames;var dy=Object.getPrototypeOf,py=Object.prototype.hasOwnProperty;var $p=(t,e)=>()=>(e||t((e={exports:{}}).exports,e),e.exports);var my=(t,e,n,r)=>{if(e&&typeof e=="object"||typeof e=="function")for(let i of hy(e))!py.call(t,i)&&i!==n&&Zp(t,i,{get:()=>e[i],enumerable:!(r=fy(e,i))||r.enumerable});return t};var Pa=(t,e,n)=>(n=t!=null?cy(dy(t)):{},my(e||!t||!t.__esModule?Zp(n,"default",{value:t,enumerable:!0}):n,t));var Hc=$p((Ud,Od)=>{(function(t,e){typeof Ud=="object"&&typeof Od<"u"?Od.exports=e():typeof define=="function"&&define.amd?define(e):(t=typeof globalThis<"u"?globalThis:t||self,t.typed=e())})(Ud,(function(){"use strict";function t(){return!0}function e(){return!1}function n(){}let r="Argument is not a typed-function.";function i(){function s(R){return typeof R=="object"&&R!==null&&R.constructor===Object}let a=[{name:"number",test:function(R){return typeof R=="number"}},{name:"string",test:function(R){return typeof R=="string"}},{name:"boolean",test:function(R){return typeof R=="boolean"}},{name:"Function",test:function(R){return typeof R=="function"}},{name:"Array",test:Array.isArray},{name:"Date",test:function(R){return R instanceof Date}},{name:"RegExp",test:function(R){return R instanceof RegExp}},{name:"Object",test:s},{name:"null",test:function(R){return R===null}},{name:"undefined",test:function(R){return R===void 0}}],l={name:"any",test:t,isAny:!0},u,c,f=0,h={createCount:0};function d(R){let I=u.get(R);if(I)return I;let V='Unknown type "'+R+'"',X=R.toLowerCase(),G;for(G of c)if(G.toLowerCase()===X){V+='. Did you mean "'+G+'" ?';break}throw new TypeError(V)}function x(R){let I=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"any",V=I?d(I).index:c.length,X=[];for(let W=0;W<R.length;++W){if(!R[W]||typeof R[W].name!="string"||typeof R[W].test!="function")throw new TypeError("Object with properties {name: string, test: function} expected");let ie=R[W].name;if(u.has(ie))throw new TypeError('Duplicate type name "'+ie+'"');X.push(ie),u.set(ie,{name:ie,test:R[W].test,isAny:R[W].isAny,index:V+W,conversionsTo:[]})}let G=c.slice(V);c=c.slice(0,V).concat(X).concat(G);for(let W=V+X.length;W<c.length;++W)u.get(c[W]).index=W}function p(){u=new Map,c=[],f=0,x([l],!1)}p(),x(a);function g(){let R;for(R of c)u.get(R).conversionsTo=[];f=0}function m(R){let I=c.filter(V=>{let X=u.get(V);return!X.isAny&&X.test(R)});return I.length?I:["any"]}function b(R){return R&&typeof R=="function"&&"_typedFunctionData"in R}function v(R,I,V){if(!b(R))throw new TypeError(r);let X=V&&V.exact,G=Array.isArray(I)?I.join(","):I,W=w(G),ie=y(W);if(!X||ie in R.signatures){let L=R._typedFunctionData.signatureMap.get(ie);if(L)return L}let $=W.length,ee;if(X){ee=[];let L;for(L in R.signatures)ee.push(R._typedFunctionData.signatureMap.get(L))}else ee=R._typedFunctionData.signatures;for(let L=0;L<$;++L){let ce=W[L],pe=[],_e;for(_e of ee){let fe=U(_e.params,L);if(!(!fe||ce.restParam&&!fe.restParam)){if(!fe.hasAny){let ue=S(fe);if(ce.types.some(Ee=>!ue.has(Ee.name)))continue}pe.push(_e)}}if(ee=pe,ee.length===0)break}let Q;for(Q of ee)if(Q.params.length<=$)return Q;throw new TypeError("Signature not found (signature: "+(R.name||"unnamed")+"("+y(W,", ")+"))")}function _(R,I,V){return v(R,I,V).implementation}function M(R,I){let V=d(I);if(V.test(R))return R;let X=V.conversionsTo;if(X.length===0)throw new Error("There are no conversions to "+I+" defined.");for(let G=0;G<X.length;G++)if(d(X[G].from).test(R))return X[G].convert(R);throw new Error("Cannot convert "+R+" to "+I)}function y(R){let I=arguments.length>1&&arguments[1]!==void 0?arguments[1]:",";return R.map(V=>V.name).join(I)}function E(R){let I=R.indexOf("...")===0,X=(I?R.length>3?R.slice(3):"any":R).split("|").map($=>d($.trim())),G=!1,W=I?"...":"";return{types:X.map(function($){return G=$.isAny||G,W+=$.name+"|",{name:$.name,typeIndex:$.index,test:$.test,isAny:$.isAny,conversion:null,conversionIndex:-1}}),name:W.slice(0,-1),hasAny:G,hasConversion:!1,restParam:I}}function D(R){let I=R.types.map(ie=>ie.name),V=ze(I),X=R.hasAny,G=R.name,W=V.map(function(ie){let $=d(ie.from);return X=$.isAny||X,G+="|"+ie.from,{name:ie.from,typeIndex:$.index,test:$.test,isAny:$.isAny,conversion:ie,conversionIndex:ie.index}});return{types:R.types.concat(W),name:G,hasAny:X,hasConversion:W.length>0,restParam:R.restParam}}function S(R){return R.typeSet||(R.typeSet=new Set,R.types.forEach(I=>R.typeSet.add(I.name))),R.typeSet}function w(R){let I=[];if(typeof R!="string")throw new TypeError("Signatures must be strings");let V=R.trim();if(V==="")return I;let X=V.split(",");for(let G=0;G<X.length;++G){let W=E(X[G].trim());if(W.restParam&&G!==X.length-1)throw new SyntaxError('Unexpected rest parameter "'+X[G]+'": only allowed for the last parameter');if(W.types.length===0)return null;I.push(W)}return I}function C(R){let I=Ne(R);return I?I.restParam:!1}function F(R){if(!R||R.types.length===0)return t;if(R.types.length===1)return d(R.types[0].name).test;if(R.types.length===2){let I=d(R.types[0].name).test,V=d(R.types[1].name).test;return function(G){return I(G)||V(G)}}else{let I=R.types.map(function(V){return d(V.name).test});return function(X){for(let G=0;G<I.length;G++)if(I[G](X))return!0;return!1}}}function O(R){let I,V,X;if(C(R)){I=Je(R).map(F);let G=I.length,W=F(Ne(R)),ie=function($){for(let ee=G;ee<$.length;ee++)if(!W($[ee]))return!1;return!0};return function(ee){for(let Q=0;Q<I.length;Q++)if(!I[Q](ee[Q]))return!1;return ie(ee)&&ee.length>=G+1}}else return R.length===0?function(W){return W.length===0}:R.length===1?(V=F(R[0]),function(W){return V(W[0])&&W.length===1}):R.length===2?(V=F(R[0]),X=F(R[1]),function(W){return V(W[0])&&X(W[1])&&W.length===2}):(I=R.map(F),function(W){for(let ie=0;ie<I.length;ie++)if(!I[ie](W[ie]))return!1;return W.length===I.length})}function U(R,I){return I<R.length?R[I]:C(R)?Ne(R):null}function z(R,I){let V=U(R,I);return V?S(V):new Set}function B(R){return R.conversion===null||R.conversion===void 0}function J(R,I){let V=new Set;return R.forEach(X=>{let G=z(X.params,I),W;for(W of G)V.add(W)}),V.has("any")?["any"]:Array.from(V)}function H(R,I,V){let X,G,W=R||"unnamed",ie=V,$;for($=0;$<I.length;$++){let ce=[];if(ie.forEach(pe=>{let _e=U(pe.params,$),fe=F(_e);($<pe.params.length||C(pe.params))&&fe(I[$])&&ce.push(pe)}),ce.length===0){if(G=J(ie,$),G.length>0){let pe=m(I[$]);return X=new TypeError("Unexpected type of argument in function "+W+" (expected: "+G.join(" or ")+", actual: "+pe.join(" | ")+", index: "+$+")"),X.data={category:"wrongType",fn:W,index:$,actual:pe,expected:G},X}}else ie=ce}let ee=ie.map(function(ce){return C(ce.params)?1/0:ce.params.length});if(I.length<Math.min.apply(null,ee))return G=J(ie,$),X=new TypeError("Too few arguments in function "+W+" (expected: "+G.join(" or ")+", index: "+I.length+")"),X.data={category:"tooFewArgs",fn:W,index:I.length,expected:G},X;let Q=Math.max.apply(null,ee);if(I.length>Q)return X=new TypeError("Too many arguments in function "+W+" (expected: "+Q+", actual: "+I.length+")"),X.data={category:"tooManyArgs",fn:W,index:I.length,expectedLength:Q},X;let L=[];for(let ce=0;ce<I.length;++ce)L.push(m(I[ce]).join("|"));return X=new TypeError('Arguments of type "'+L.join(", ")+'" do not match any of the defined signatures of function '+W+"."),X.data={category:"mismatch",actual:L},X}function ne(R){let I=c.length+1;for(let V=0;V<R.types.length;V++)I=Math.min(I,R.types[V].typeIndex);return I}function se(R){let I=f+1;for(let V=0;V<R.types.length;V++)B(R.types[V])||(I=Math.min(I,R.types[V].conversionIndex));return I}function ge(R,I){if(R.hasAny){if(!I.hasAny)return .1}else if(I.hasAny)return-.1;if(R.restParam){if(!I.restParam)return .01}else if(I.restParam)return-.01;let V=ne(R)-ne(I);if(V<0)return-.001;if(V>0)return .001;let X=se(R),G=se(I);if(R.hasConversion){if(!I.hasConversion)return(1+X)*1e-6}else if(I.hasConversion)return-(1+G)*1e-6;let W=X-G;return W<0?-1e-7:W>0?1e-7:0}function Te(R,I){let V=R.params,X=I.params,G=Ne(V),W=Ne(X),ie=C(V),$=C(X);if(ie&&G.hasAny){if(!$||!W.hasAny)return 1e7}else if($&&W.hasAny)return-1e7;let ee=0,Q=0,L;for(L of V)L.hasAny&&++ee,L.hasConversion&&++Q;let ce=0,pe=0;for(L of X)L.hasAny&&++ce,L.hasConversion&&++pe;if(ee!==ce)return(ee-ce)*1e6;if(ie&&G.hasConversion){if(!$||!W.hasConversion)return 1e5}else if($&&W.hasConversion)return-1e5;if(Q!==pe)return(Q-pe)*1e4;if(ie){if(!$)return 1e3}else if($)return-1e3;let _e=(V.length-X.length)*(ie?-100:100);if(_e!==0)return _e;let fe=[],ue=0;for(let nt=0;nt<V.length;++nt){let pn=ge(V[nt],X[nt]);fe.push(pn),ue+=pn}if(ue!==0)return(ue<0?-10:10)+ue;let Ee,We=9,mt=We/(fe.length+1);for(Ee of fe){if(Ee!==0)return(Ee<0?-We:We)+Ee;We-=mt}return 0}function ze(R){if(R.length===0)return[];let I=R.map(d);if(R.length===1)return I[0].conversionsTo;let V=new Set(R),X=new Set;for(let W=0;W<I.length;++W)for(let ie of I[W].conversionsTo)V.has(ie.from)||X.add(ie.from);let G=[];for(let W of X){let ie=f+1,$=null;for(let ee=0;ee<I.length;++ee)for(let Q of I[ee].conversionsTo)Q.from===W&&Q.index<ie&&(ie=Q.index,$=Q);G.push($)}return G}function Ze(R,I){let V=I,X="";if(R.some(W=>W.hasConversion)){let W=C(R),ie=R.map(ke);X=ie.map($=>$.name).join(";"),V=function(){let ee=[],Q=W?arguments.length-1:arguments.length;for(let L=0;L<Q;L++)ee[L]=ie[L](arguments[L]);return W&&(ee[Q]=arguments[Q].map(ie[Q])),I.apply(this,ee)}}let G=V;if(C(R)){let W=R.length-1;G=function(){return V.apply(this,Be(arguments,0,W).concat([Be(arguments,W)]))}}return X&&Object.defineProperty(G,"name",{value:X}),G}function ke(R){let I,V,X,G,W=[],ie=[],$="";R.types.forEach(function(Q){Q.conversion&&($+=Q.conversion.from+"~>"+Q.conversion.to+",",W.push(d(Q.conversion.from).test),ie.push(Q.conversion.convert))}),$?$=$.slice(0,-1):$="pass";let ee=Q=>Q;switch(ie.length){case 0:break;case 1:I=W[0],X=ie[0],ee=function(L){return I(L)?X(L):L};break;case 2:I=W[0],V=W[1],X=ie[0],G=ie[1],ee=function(L){return I(L)?X(L):V(L)?G(L):L};break;default:ee=function(L){for(let ce=0;ce<ie.length;ce++)if(W[ce](L))return ie[ce](L);return L}}return Object.defineProperty(ee,"name",{value:$}),ee}function re(R){function I(V,X,G){if(X<V.length){let W=V[X],ie=[];if(W.restParam){let $=W.types.filter(B);$.length<W.types.length&&ie.push({types:$,name:"..."+$.map(ee=>ee.name).join("|"),hasAny:$.some(ee=>ee.isAny),hasConversion:!1,restParam:!0}),ie.push(W)}else ie=W.types.map(function($){return{types:[$],name:$.name,hasAny:$.isAny,hasConversion:$.conversion,restParam:!1}});return pt(ie,function($){return I(V,X+1,G.concat([$]))})}else return[G]}return I(R,0,[])}function ae(R,I){let V=Math.max(R.length,I.length);for(let $=0;$<V;$++){let ee=z(R,$),Q=z(I,$),L=!1,ce;for(ce of Q)if(ee.has(ce)){L=!0;break}if(!L)return!1}let X=R.length,G=I.length,W=C(R),ie=C(I);return W?ie?X===G:G>=X:ie?X>=G:X===G}function Se(R){return R.map(I=>P(I)?It(I.referToSelf.callback):Et(I)?$e(I.referTo.references,I.referTo.callback):I)}function De(R,I,V){let X=[],G;for(G of R){let W=V[G];if(typeof W!="number")throw new TypeError('No definition for referenced signature "'+G+'"');if(W=I[W],typeof W!="function")return!1;X.push(W)}return X}function xe(R,I,V){let X=Se(R),G=new Array(X.length).fill(!1),W=!0;for(;W;){W=!1;let ie=!0;for(let $=0;$<X.length;++$){if(G[$])continue;let ee=X[$];if(P(ee))X[$]=ee.referToSelf.callback(V),X[$].referToSelf=ee.referToSelf,G[$]=!0,ie=!1;else if(Et(ee)){let Q=De(ee.referTo.references,X,I);Q?(X[$]=ee.referTo.callback.apply(this,Q),X[$].referTo=ee.referTo,G[$]=!0,ie=!1):W=!0}}if(ie&&W)throw new SyntaxError("Circular reference detected in resolving typed.referTo")}return X}function Xe(R){let I=/\bthis(\(|\.signatures\b)/;Object.keys(R).forEach(V=>{let X=R[V];if(I.test(X.toString()))throw new SyntaxError("Using `this` to self-reference a function is deprecated since typed-function@3. Use typed.referTo and typed.referToSelf instead.")})}function ut(R,I){if(h.createCount++,Object.keys(I).length===0)throw new SyntaxError("No signatures provided");h.warnAgainstDeprecatedThis&&Xe(I);let V=[],X=[],G={},W=[],ie;for(ie in I){if(!Object.prototype.hasOwnProperty.call(I,ie))continue;let ye=w(ie);if(!ye)continue;V.forEach(function(xt){if(ae(xt,ye))throw new TypeError('Conflicting signatures "'+y(xt)+'" and "'+y(ye)+'".')}),V.push(ye);let Ce=X.length;X.push(I[ie]);let tt=ye.map(D),lt;for(lt of re(tt)){let xt=y(lt);W.push({params:lt,name:xt,fn:Ce}),lt.every(_t=>!_t.hasConversion)&&(G[xt]=Ce)}}W.sort(Te);let $=xe(X,G,Oe),ee;for(ee in G)Object.prototype.hasOwnProperty.call(G,ee)&&(G[ee]=$[G[ee]]);let Q=[],L=new Map;for(ee of W)L.has(ee.name)||(ee.fn=$[ee.fn],Q.push(ee),L.set(ee.name,ee));let ce=Q[0]&&Q[0].params.length<=2&&!C(Q[0].params),pe=Q[1]&&Q[1].params.length<=2&&!C(Q[1].params),_e=Q[2]&&Q[2].params.length<=2&&!C(Q[2].params),fe=Q[3]&&Q[3].params.length<=2&&!C(Q[3].params),ue=Q[4]&&Q[4].params.length<=2&&!C(Q[4].params),Ee=Q[5]&&Q[5].params.length<=2&&!C(Q[5].params),We=ce&&pe&&_e&&fe&&ue&&Ee;for(let ye=0;ye<Q.length;++ye)Q[ye].test=O(Q[ye].params);let mt=ce?F(Q[0].params[0]):e,nt=pe?F(Q[1].params[0]):e,pn=_e?F(Q[2].params[0]):e,Nn=fe?F(Q[3].params[0]):e,Da=ue?F(Q[4].params[0]):e,_r=Ee?F(Q[5].params[0]):e,ls=ce?F(Q[0].params[1]):e,Aa=pe?F(Q[1].params[1]):e,Ca=_e?F(Q[2].params[1]):e,oo=fe?F(Q[3].params[1]):e,Ta=ue?F(Q[4].params[1]):e,so=Ee?F(Q[5].params[1]):e;for(let ye=0;ye<Q.length;++ye)Q[ye].implementation=Ze(Q[ye].params,Q[ye].fn);let Ra=ce?Q[0].implementation:n,Fa=pe?Q[1].implementation:n,gf=_e?Q[2].implementation:n,xf=fe?Q[3].implementation:n,vf=ue?Q[4].implementation:n,_f=Ee?Q[5].implementation:n,yf=ce?Q[0].params.length:-1,Mf=pe?Q[1].params.length:-1,T=_e?Q[2].params.length:-1,q=fe?Q[3].params.length:-1,j=ue?Q[4].params.length:-1,te=Ee?Q[5].params.length:-1,Y=We?6:0,me=Q.length,be=Q.map(ye=>ye.test),Pe=Q.map(ye=>ye.implementation),Re=function(){for(let Ce=Y;Ce<me;Ce++)if(be[Ce](arguments))return Pe[Ce].apply(this,arguments);return h.onMismatch(R,arguments,Q)};function Oe(ye,Ce){return arguments.length===yf&&mt(ye)&&ls(Ce)?Ra.apply(this,arguments):arguments.length===Mf&&nt(ye)&&Aa(Ce)?Fa.apply(this,arguments):arguments.length===T&&pn(ye)&&Ca(Ce)?gf.apply(this,arguments):arguments.length===q&&Nn(ye)&&oo(Ce)?xf.apply(this,arguments):arguments.length===j&&Da(ye)&&Ta(Ce)?vf.apply(this,arguments):arguments.length===te&&_r(ye)&&so(Ce)?_f.apply(this,arguments):Re.apply(this,arguments)}try{Object.defineProperty(Oe,"name",{value:R})}catch{}return Oe.signatures=G,Oe._typedFunctionData={signatures:Q,signatureMap:L},Oe}function N(R,I,V){throw H(R,I,V)}function Je(R){return Be(R,0,R.length-1)}function Ne(R){return R[R.length-1]}function Be(R,I,V){return Array.prototype.slice.call(R,I,V)}function Ae(R,I){for(let V=0;V<R.length;V++)if(I(R[V]))return R[V]}function pt(R,I){return Array.prototype.concat.apply([],R.map(I))}function Fe(){let R=Je(arguments).map(V=>y(w(V))),I=Ne(arguments);if(typeof I!="function")throw new TypeError("Callback function expected as last argument");return $e(R,I)}function $e(R,I){return{referTo:{references:R,callback:I}}}function It(R){if(typeof R!="function")throw new TypeError("Callback function expected as first argument");return{referToSelf:{callback:R}}}function Et(R){return R&&typeof R.referTo=="object"&&Array.isArray(R.referTo.references)&&typeof R.referTo.callback=="function"}function P(R){return R&&typeof R.referToSelf=="object"&&typeof R.referToSelf.callback=="function"}function A(R,I){if(!R)return I;if(I&&I!==R){let V=new Error("Function names do not match (expected: "+R+", actual: "+I+")");throw V.data={actual:I,expected:R},V}return R}function Z(R){let I;for(let V in R)Object.prototype.hasOwnProperty.call(R,V)&&(b(R[V])||typeof R[V].signature=="string")&&(I=A(I,R[V].name));return I}function le(R,I){let V;for(V in I)if(Object.prototype.hasOwnProperty.call(I,V)){if(V in R&&I[V]!==R[V]){let X=new Error('Signature "'+V+'" is defined twice');throw X.data={signature:V,sourceFunction:I[V],destFunction:R[V]},X}R[V]=I[V]}}let de=h;h=function(R){let I=typeof R=="string",V=I?1:0,X=I?R:"",G={};for(let W=V;W<arguments.length;++W){let ie=arguments[W],$={},ee;if(typeof ie=="function"?(ee=ie.name,typeof ie.signature=="string"?$[ie.signature]=ie:b(ie)&&($=ie.signatures)):s(ie)&&($=ie,I||(ee=Z(ie))),Object.keys($).length===0){let Q=new TypeError("Argument to 'typed' at index "+W+" is not a (typed) function, nor an object with signatures as keys and functions as values.");throw Q.data={index:W,argument:ie},Q}I||(X=A(X,ee)),le(G,$)}return ut(X||"",G)},h.create=i,h.createCount=de.createCount,h.onMismatch=N,h.throwMismatchError=N,h.createError=H,h.clear=p,h.clearConversions=g,h.addTypes=x,h._findType=d,h.referTo=Fe,h.referToSelf=It,h.convert=M,h.findSignature=v,h.find=_,h.isTypedFunction=b,h.warnAgainstDeprecatedThis=!0,h.addType=function(R,I){let V="any";I!==!1&&u.has("Object")&&(V="Object"),h.addTypes([R],V)};function oe(R){if(!R||typeof R.from!="string"||typeof R.to!="string"||typeof R.convert!="function")throw new TypeError("Object with properties {from: string, to: string, convert: function} expected");if(R.to===R.from)throw new SyntaxError('Illegal to define conversion from "'+R.from+'" to itself.')}return h.addConversion=function(R){let I=arguments.length>1&&arguments[1]!==void 0?arguments[1]:{override:!1};oe(R);let V=d(R.to),X=V.conversionsTo.find(G=>G.from===R.from);if(X)if(I&&I.override)h.removeConversion({from:X.from,to:R.to,convert:X.convert});else throw new Error('There is already a conversion from "'+R.from+'" to "'+V.name+'"');V.conversionsTo.push({from:R.from,to:V.name,convert:R.convert,index:f++})},h.addConversions=function(R,I){R.forEach(V=>h.addConversion(V,I))},h.removeConversion=function(R){oe(R);let I=d(R.to),V=Ae(I.conversionsTo,G=>G.from===R.from);if(!V)throw new Error("Attempt to remove nonexistent conversion from "+R.from+" to "+R.to);if(V.convert!==R.convert)throw new Error("Conversion to remove does not match existing conversion");let X=I.conversionsTo.indexOf(V);I.conversionsTo.splice(X,1)},h.resolve=function(R,I){if(!b(R))throw new TypeError(r);let V=R._typedFunctionData.signatures;for(let X=0;X<V.length;++X)if(V[X].test(I))return V[X];return null},h}var o=i();return o}))});var X_=$p((bG,Wp)=>{function Gp(){}Gp.prototype={on:function(t,e,n){var r=this.e||(this.e={});return(r[t]||(r[t]=[])).push({fn:e,ctx:n}),this},once:function(t,e,n){var r=this;function i(){r.off(t,i),e.apply(n,arguments)}return i._=e,this.on(t,i,n)},emit:function(t){var e=[].slice.call(arguments,1),n=((this.e||(this.e={}))[t]||[]).slice(),r=0,i=n.length;for(r;r<i;r++)n[r].fn.apply(n[r].ctx,e);return this},off:function(t,e){var n=this.e||(this.e={}),r=n[t],i=[];if(r&&e)for(var o=0,s=r.length;o<s;o++)r[o].fn!==e&&r[o].fn._!==e&&i.push(r[o]);return i.length?n[t]=i:delete n[t],this}};Wp.exports=Gp;Wp.exports.TinyEmitter=Gp});/**
 * @license
 * Copyright 2010-2025 Three.js Authors
 * SPDX-License-Identifier: MIT
 */var jr={LEFT:0,MIDDLE:1,RIGHT:2,ROTATE:0,DOLLY:1,PAN:2},ei={ROTATE:0,PAN:1,DOLLY_PAN:2,DOLLY_ROTATE:3},ym=0,ih=1,Mm=2;var oh=1,Sm=2,cr=3,Ar=0,fn=1,fr=2,Tr=0,Ei=1,sh=2,ah=3,uh=4,wm=5,$r=100,bm=101,Em=102,Dm=103,Am=104,Cm=200,Tm=201,Rm=202,Fm=203,nu=204,ru=205,Pm=206,Im=207,Nm=208,Lm=209,Bm=210,Um=211,Om=212,zm=213,km=214,Lu=0,Bu=1,Uu=2,Di=3,Ou=4,zu=5,ku=6,Vu=7,lh=0,Vm=1,Hm=2,Rr=0,Gm=1,Wm=2,qm=3,Xm=4,Ym=5,Zm=6,$m=7;var ch=300,Pi=301,Ii=302,Hu=303,Gu=304,qs=306,iu=1e3,Zr=1001,ou=1002,zn=1003,Jm=1004;var Xs=1005;var Jn=1006,Wu=1007;var ti=1008;var er=1009,fh=1010,hh=1011,No=1012,qu=1013,ni=1014,hr=1015,Lo=1016,Xu=1017,Yu=1018,Bo=1020,dh=35902,ph=35899,mh=1021,gh=1022,Hn=1023,wo=1026,Uo=1027,xh=1028,Zu=1029,vh=1030,$u=1031;var Ju=1033,Ys=33776,Zs=33777,$s=33778,Js=33779,Ku=35840,Qu=35841,ju=35842,el=35843,tl=36196,nl=37492,rl=37496,il=37808,ol=37809,sl=37810,al=37811,ul=37812,ll=37813,cl=37814,fl=37815,hl=37816,dl=37817,pl=37818,ml=37819,gl=37820,xl=37821,vl=36492,_l=36494,yl=36495,Ml=36283,Sl=36284,wl=36285,bl=36286;var ys=2300,su=2301,tu=2302,Jf=2400,Kf=2401,Qf=2402;var Km=3200,Qm=3201;var _h=0,jm=1,Fr="",An="srgb",Ai="srgb-linear",Ms="linear",gt="srgb";var bi=7680;var jf=519,eg=512,tg=513,ng=514,yh=515,rg=516,ig=517,og=518,sg=519,eh=35044;var Mh="300 es",$n=2e3,Ss=2001;var ur=class{addEventListener(e,n){this._listeners===void 0&&(this._listeners={});let r=this._listeners;r[e]===void 0&&(r[e]=[]),r[e].indexOf(n)===-1&&r[e].push(n)}hasEventListener(e,n){let r=this._listeners;return r===void 0?!1:r[e]!==void 0&&r[e].indexOf(n)!==-1}removeEventListener(e,n){let r=this._listeners;if(r===void 0)return;let i=r[e];if(i!==void 0){let o=i.indexOf(n);o!==-1&&i.splice(o,1)}}dispatchEvent(e){let n=this._listeners;if(n===void 0)return;let r=n[e.type];if(r!==void 0){e.target=this;let i=r.slice(0);for(let o=0,s=i.length;o<s;o++)i[o].call(this,e);e.target=null}}},jt=["00","01","02","03","04","05","06","07","08","09","0a","0b","0c","0d","0e","0f","10","11","12","13","14","15","16","17","18","19","1a","1b","1c","1d","1e","1f","20","21","22","23","24","25","26","27","28","29","2a","2b","2c","2d","2e","2f","30","31","32","33","34","35","36","37","38","39","3a","3b","3c","3d","3e","3f","40","41","42","43","44","45","46","47","48","49","4a","4b","4c","4d","4e","4f","50","51","52","53","54","55","56","57","58","59","5a","5b","5c","5d","5e","5f","60","61","62","63","64","65","66","67","68","69","6a","6b","6c","6d","6e","6f","70","71","72","73","74","75","76","77","78","79","7a","7b","7c","7d","7e","7f","80","81","82","83","84","85","86","87","88","89","8a","8b","8c","8d","8e","8f","90","91","92","93","94","95","96","97","98","99","9a","9b","9c","9d","9e","9f","a0","a1","a2","a3","a4","a5","a6","a7","a8","a9","aa","ab","ac","ad","ae","af","b0","b1","b2","b3","b4","b5","b6","b7","b8","b9","ba","bb","bc","bd","be","bf","c0","c1","c2","c3","c4","c5","c6","c7","c8","c9","ca","cb","cc","cd","ce","cf","d0","d1","d2","d3","d4","d5","d6","d7","d8","d9","da","db","dc","dd","de","df","e0","e1","e2","e3","e4","e5","e6","e7","e8","e9","ea","eb","ec","ed","ee","ef","f0","f1","f2","f3","f4","f5","f6","f7","f8","f9","fa","fb","fc","fd","fe","ff"],Jp=1234567,gs=Math.PI/180,bo=180/Math.PI;function Oo(){let t=Math.random()*4294967295|0,e=Math.random()*4294967295|0,n=Math.random()*4294967295|0,r=Math.random()*4294967295|0;return(jt[t&255]+jt[t>>8&255]+jt[t>>16&255]+jt[t>>24&255]+"-"+jt[e&255]+jt[e>>8&255]+"-"+jt[e>>16&15|64]+jt[e>>24&255]+"-"+jt[n&63|128]+jt[n>>8&255]+"-"+jt[n>>16&255]+jt[n>>24&255]+jt[r&255]+jt[r>>8&255]+jt[r>>16&255]+jt[r>>24&255]).toLowerCase()}function Qe(t,e,n){return Math.max(e,Math.min(n,t))}function Sh(t,e){return(t%e+e)%e}function gy(t,e,n,r,i){return r+(t-e)*(i-r)/(n-e)}function xy(t,e,n){return t!==e?(n-t)/(e-t):0}function xs(t,e,n){return(1-n)*t+n*e}function vy(t,e,n,r){return xs(t,e,1-Math.exp(-n*r))}function _y(t,e=1){return e-Math.abs(Sh(t,e*2)-e)}function yy(t,e,n){return t<=e?0:t>=n?1:(t=(t-e)/(n-e),t*t*(3-2*t))}function My(t,e,n){return t<=e?0:t>=n?1:(t=(t-e)/(n-e),t*t*t*(t*(t*6-15)+10))}function Sy(t,e){return t+Math.floor(Math.random()*(e-t+1))}function wy(t,e){return t+Math.random()*(e-t)}function by(t){return t*(.5-Math.random())}function Ey(t){t!==void 0&&(Jp=t);let e=Jp+=1831565813;return e=Math.imul(e^e>>>15,e|1),e^=e+Math.imul(e^e>>>7,e|61),((e^e>>>14)>>>0)/4294967296}function Dy(t){return t*gs}function Ay(t){return t*bo}function Cy(t){return(t&t-1)===0&&t!==0}function Ty(t){return Math.pow(2,Math.ceil(Math.log(t)/Math.LN2))}function Ry(t){return Math.pow(2,Math.floor(Math.log(t)/Math.LN2))}function Fy(t,e,n,r,i){let o=Math.cos,s=Math.sin,a=o(n/2),l=s(n/2),u=o((e+r)/2),c=s((e+r)/2),f=o((e-r)/2),h=s((e-r)/2),d=o((r-e)/2),x=s((r-e)/2);switch(i){case"XYX":t.set(a*c,l*f,l*h,a*u);break;case"YZY":t.set(l*h,a*c,l*f,a*u);break;case"ZXZ":t.set(l*f,l*h,a*c,a*u);break;case"XZX":t.set(a*c,l*x,l*d,a*u);break;case"YXY":t.set(l*d,a*c,l*x,a*u);break;case"ZYZ":t.set(l*x,l*d,a*c,a*u);break;default:console.warn("THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: "+i)}}function Mo(t,e){switch(e.constructor){case Float32Array:return t;case Uint32Array:return t/4294967295;case Uint16Array:return t/65535;case Uint8Array:return t/255;case Int32Array:return Math.max(t/2147483647,-1);case Int16Array:return Math.max(t/32767,-1);case Int8Array:return Math.max(t/127,-1);default:throw new Error("Invalid component type.")}}function ln(t,e){switch(e.constructor){case Float32Array:return t;case Uint32Array:return Math.round(t*4294967295);case Uint16Array:return Math.round(t*65535);case Uint8Array:return Math.round(t*255);case Int32Array:return Math.round(t*2147483647);case Int16Array:return Math.round(t*32767);case Int8Array:return Math.round(t*127);default:throw new Error("Invalid component type.")}}var wh={DEG2RAD:gs,RAD2DEG:bo,generateUUID:Oo,clamp:Qe,euclideanModulo:Sh,mapLinear:gy,inverseLerp:xy,lerp:xs,damp:vy,pingpong:_y,smoothstep:yy,smootherstep:My,randInt:Sy,randFloat:wy,randFloatSpread:by,seededRandom:Ey,degToRad:Dy,radToDeg:Ay,isPowerOfTwo:Cy,ceilPowerOfTwo:Ty,floorPowerOfTwo:Ry,setQuaternionFromProperEuler:Fy,normalize:ln,denormalize:Mo},Ie=class t{constructor(e=0,n=0){t.prototype.isVector2=!0,this.x=e,this.y=n}get width(){return this.x}set width(e){this.x=e}get height(){return this.y}set height(e){this.y=e}set(e,n){return this.x=e,this.y=n,this}setScalar(e){return this.x=e,this.y=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setComponent(e,n){switch(e){case 0:this.x=n;break;case 1:this.y=n;break;default:throw new Error("index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;default:throw new Error("index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y)}copy(e){return this.x=e.x,this.y=e.y,this}add(e){return this.x+=e.x,this.y+=e.y,this}addScalar(e){return this.x+=e,this.y+=e,this}addVectors(e,n){return this.x=e.x+n.x,this.y=e.y+n.y,this}addScaledVector(e,n){return this.x+=e.x*n,this.y+=e.y*n,this}sub(e){return this.x-=e.x,this.y-=e.y,this}subScalar(e){return this.x-=e,this.y-=e,this}subVectors(e,n){return this.x=e.x-n.x,this.y=e.y-n.y,this}multiply(e){return this.x*=e.x,this.y*=e.y,this}multiplyScalar(e){return this.x*=e,this.y*=e,this}divide(e){return this.x/=e.x,this.y/=e.y,this}divideScalar(e){return this.multiplyScalar(1/e)}applyMatrix3(e){let n=this.x,r=this.y,i=e.elements;return this.x=i[0]*n+i[3]*r+i[6],this.y=i[1]*n+i[4]*r+i[7],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this}clamp(e,n){return this.x=Qe(this.x,e.x,n.x),this.y=Qe(this.y,e.y,n.y),this}clampScalar(e,n){return this.x=Qe(this.x,e,n),this.y=Qe(this.y,e,n),this}clampLength(e,n){let r=this.length();return this.divideScalar(r||1).multiplyScalar(Qe(r,e,n))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this}negate(){return this.x=-this.x,this.y=-this.y,this}dot(e){return this.x*e.x+this.y*e.y}cross(e){return this.x*e.y-this.y*e.x}lengthSq(){return this.x*this.x+this.y*this.y}length(){return Math.sqrt(this.x*this.x+this.y*this.y)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)}normalize(){return this.divideScalar(this.length()||1)}angle(){return Math.atan2(-this.y,-this.x)+Math.PI}angleTo(e){let n=Math.sqrt(this.lengthSq()*e.lengthSq());if(n===0)return Math.PI/2;let r=this.dot(e)/n;return Math.acos(Qe(r,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let n=this.x-e.x,r=this.y-e.y;return n*n+r*r}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,n){return this.x+=(e.x-this.x)*n,this.y+=(e.y-this.y)*n,this}lerpVectors(e,n,r){return this.x=e.x+(n.x-e.x)*r,this.y=e.y+(n.y-e.y)*r,this}equals(e){return e.x===this.x&&e.y===this.y}fromArray(e,n=0){return this.x=e[n],this.y=e[n+1],this}toArray(e=[],n=0){return e[n]=this.x,e[n+1]=this.y,e}fromBufferAttribute(e,n){return this.x=e.getX(n),this.y=e.getY(n),this}rotateAround(e,n){let r=Math.cos(n),i=Math.sin(n),o=this.x-e.x,s=this.y-e.y;return this.x=o*r-s*i+e.x,this.y=o*i+s*r+e.y,this}random(){return this.x=Math.random(),this.y=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y}},kn=class{constructor(e=0,n=0,r=0,i=1){this.isQuaternion=!0,this._x=e,this._y=n,this._z=r,this._w=i}static slerpFlat(e,n,r,i,o,s,a){let l=r[i+0],u=r[i+1],c=r[i+2],f=r[i+3],h=o[s+0],d=o[s+1],x=o[s+2],p=o[s+3];if(a===0){e[n+0]=l,e[n+1]=u,e[n+2]=c,e[n+3]=f;return}if(a===1){e[n+0]=h,e[n+1]=d,e[n+2]=x,e[n+3]=p;return}if(f!==p||l!==h||u!==d||c!==x){let g=1-a,m=l*h+u*d+c*x+f*p,b=m>=0?1:-1,v=1-m*m;if(v>Number.EPSILON){let M=Math.sqrt(v),y=Math.atan2(M,m*b);g=Math.sin(g*y)/M,a=Math.sin(a*y)/M}let _=a*b;if(l=l*g+h*_,u=u*g+d*_,c=c*g+x*_,f=f*g+p*_,g===1-a){let M=1/Math.sqrt(l*l+u*u+c*c+f*f);l*=M,u*=M,c*=M,f*=M}}e[n]=l,e[n+1]=u,e[n+2]=c,e[n+3]=f}static multiplyQuaternionsFlat(e,n,r,i,o,s){let a=r[i],l=r[i+1],u=r[i+2],c=r[i+3],f=o[s],h=o[s+1],d=o[s+2],x=o[s+3];return e[n]=a*x+c*f+l*d-u*h,e[n+1]=l*x+c*h+u*f-a*d,e[n+2]=u*x+c*d+a*h-l*f,e[n+3]=c*x-a*f-l*h-u*d,e}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get w(){return this._w}set w(e){this._w=e,this._onChangeCallback()}set(e,n,r,i){return this._x=e,this._y=n,this._z=r,this._w=i,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._w)}copy(e){return this._x=e.x,this._y=e.y,this._z=e.z,this._w=e.w,this._onChangeCallback(),this}setFromEuler(e,n=!0){let r=e._x,i=e._y,o=e._z,s=e._order,a=Math.cos,l=Math.sin,u=a(r/2),c=a(i/2),f=a(o/2),h=l(r/2),d=l(i/2),x=l(o/2);switch(s){case"XYZ":this._x=h*c*f+u*d*x,this._y=u*d*f-h*c*x,this._z=u*c*x+h*d*f,this._w=u*c*f-h*d*x;break;case"YXZ":this._x=h*c*f+u*d*x,this._y=u*d*f-h*c*x,this._z=u*c*x-h*d*f,this._w=u*c*f+h*d*x;break;case"ZXY":this._x=h*c*f-u*d*x,this._y=u*d*f+h*c*x,this._z=u*c*x+h*d*f,this._w=u*c*f-h*d*x;break;case"ZYX":this._x=h*c*f-u*d*x,this._y=u*d*f+h*c*x,this._z=u*c*x-h*d*f,this._w=u*c*f+h*d*x;break;case"YZX":this._x=h*c*f+u*d*x,this._y=u*d*f+h*c*x,this._z=u*c*x-h*d*f,this._w=u*c*f-h*d*x;break;case"XZY":this._x=h*c*f-u*d*x,this._y=u*d*f-h*c*x,this._z=u*c*x+h*d*f,this._w=u*c*f+h*d*x;break;default:console.warn("THREE.Quaternion: .setFromEuler() encountered an unknown order: "+s)}return n===!0&&this._onChangeCallback(),this}setFromAxisAngle(e,n){let r=n/2,i=Math.sin(r);return this._x=e.x*i,this._y=e.y*i,this._z=e.z*i,this._w=Math.cos(r),this._onChangeCallback(),this}setFromRotationMatrix(e){let n=e.elements,r=n[0],i=n[4],o=n[8],s=n[1],a=n[5],l=n[9],u=n[2],c=n[6],f=n[10],h=r+a+f;if(h>0){let d=.5/Math.sqrt(h+1);this._w=.25/d,this._x=(c-l)*d,this._y=(o-u)*d,this._z=(s-i)*d}else if(r>a&&r>f){let d=2*Math.sqrt(1+r-a-f);this._w=(c-l)/d,this._x=.25*d,this._y=(i+s)/d,this._z=(o+u)/d}else if(a>f){let d=2*Math.sqrt(1+a-r-f);this._w=(o-u)/d,this._x=(i+s)/d,this._y=.25*d,this._z=(l+c)/d}else{let d=2*Math.sqrt(1+f-r-a);this._w=(s-i)/d,this._x=(o+u)/d,this._y=(l+c)/d,this._z=.25*d}return this._onChangeCallback(),this}setFromUnitVectors(e,n){let r=e.dot(n)+1;return r<1e-8?(r=0,Math.abs(e.x)>Math.abs(e.z)?(this._x=-e.y,this._y=e.x,this._z=0,this._w=r):(this._x=0,this._y=-e.z,this._z=e.y,this._w=r)):(this._x=e.y*n.z-e.z*n.y,this._y=e.z*n.x-e.x*n.z,this._z=e.x*n.y-e.y*n.x,this._w=r),this.normalize()}angleTo(e){return 2*Math.acos(Math.abs(Qe(this.dot(e),-1,1)))}rotateTowards(e,n){let r=this.angleTo(e);if(r===0)return this;let i=Math.min(1,n/r);return this.slerp(e,i),this}identity(){return this.set(0,0,0,1)}invert(){return this.conjugate()}conjugate(){return this._x*=-1,this._y*=-1,this._z*=-1,this._onChangeCallback(),this}dot(e){return this._x*e._x+this._y*e._y+this._z*e._z+this._w*e._w}lengthSq(){return this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w}length(){return Math.sqrt(this._x*this._x+this._y*this._y+this._z*this._z+this._w*this._w)}normalize(){let e=this.length();return e===0?(this._x=0,this._y=0,this._z=0,this._w=1):(e=1/e,this._x=this._x*e,this._y=this._y*e,this._z=this._z*e,this._w=this._w*e),this._onChangeCallback(),this}multiply(e){return this.multiplyQuaternions(this,e)}premultiply(e){return this.multiplyQuaternions(e,this)}multiplyQuaternions(e,n){let r=e._x,i=e._y,o=e._z,s=e._w,a=n._x,l=n._y,u=n._z,c=n._w;return this._x=r*c+s*a+i*u-o*l,this._y=i*c+s*l+o*a-r*u,this._z=o*c+s*u+r*l-i*a,this._w=s*c-r*a-i*l-o*u,this._onChangeCallback(),this}slerp(e,n){if(n===0)return this;if(n===1)return this.copy(e);let r=this._x,i=this._y,o=this._z,s=this._w,a=s*e._w+r*e._x+i*e._y+o*e._z;if(a<0?(this._w=-e._w,this._x=-e._x,this._y=-e._y,this._z=-e._z,a=-a):this.copy(e),a>=1)return this._w=s,this._x=r,this._y=i,this._z=o,this;let l=1-a*a;if(l<=Number.EPSILON){let d=1-n;return this._w=d*s+n*this._w,this._x=d*r+n*this._x,this._y=d*i+n*this._y,this._z=d*o+n*this._z,this.normalize(),this}let u=Math.sqrt(l),c=Math.atan2(u,a),f=Math.sin((1-n)*c)/u,h=Math.sin(n*c)/u;return this._w=s*f+this._w*h,this._x=r*f+this._x*h,this._y=i*f+this._y*h,this._z=o*f+this._z*h,this._onChangeCallback(),this}slerpQuaternions(e,n,r){return this.copy(e).slerp(n,r)}random(){let e=2*Math.PI*Math.random(),n=2*Math.PI*Math.random(),r=Math.random(),i=Math.sqrt(1-r),o=Math.sqrt(r);return this.set(i*Math.sin(e),i*Math.cos(e),o*Math.sin(n),o*Math.cos(n))}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._w===this._w}fromArray(e,n=0){return this._x=e[n],this._y=e[n+1],this._z=e[n+2],this._w=e[n+3],this._onChangeCallback(),this}toArray(e=[],n=0){return e[n]=this._x,e[n+1]=this._y,e[n+2]=this._z,e[n+3]=this._w,e}fromBufferAttribute(e,n){return this._x=e.getX(n),this._y=e.getY(n),this._z=e.getZ(n),this._w=e.getW(n),this._onChangeCallback(),this}toJSON(){return this.toArray()}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._w}},k=class t{constructor(e=0,n=0,r=0){t.prototype.isVector3=!0,this.x=e,this.y=n,this.z=r}set(e,n,r){return r===void 0&&(r=this.z),this.x=e,this.y=n,this.z=r,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setComponent(e,n){switch(e){case 0:this.x=n;break;case 1:this.y=n;break;case 2:this.z=n;break;default:throw new Error("index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;default:throw new Error("index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y,this.z)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this}addVectors(e,n){return this.x=e.x+n.x,this.y=e.y+n.y,this.z=e.z+n.z,this}addScaledVector(e,n){return this.x+=e.x*n,this.y+=e.y*n,this.z+=e.z*n,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this}subVectors(e,n){return this.x=e.x-n.x,this.y=e.y-n.y,this.z=e.z-n.z,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this}multiplyVectors(e,n){return this.x=e.x*n.x,this.y=e.y*n.y,this.z=e.z*n.z,this}applyEuler(e){return this.applyQuaternion(Kp.setFromEuler(e))}applyAxisAngle(e,n){return this.applyQuaternion(Kp.setFromAxisAngle(e,n))}applyMatrix3(e){let n=this.x,r=this.y,i=this.z,o=e.elements;return this.x=o[0]*n+o[3]*r+o[6]*i,this.y=o[1]*n+o[4]*r+o[7]*i,this.z=o[2]*n+o[5]*r+o[8]*i,this}applyNormalMatrix(e){return this.applyMatrix3(e).normalize()}applyMatrix4(e){let n=this.x,r=this.y,i=this.z,o=e.elements,s=1/(o[3]*n+o[7]*r+o[11]*i+o[15]);return this.x=(o[0]*n+o[4]*r+o[8]*i+o[12])*s,this.y=(o[1]*n+o[5]*r+o[9]*i+o[13])*s,this.z=(o[2]*n+o[6]*r+o[10]*i+o[14])*s,this}applyQuaternion(e){let n=this.x,r=this.y,i=this.z,o=e.x,s=e.y,a=e.z,l=e.w,u=2*(s*i-a*r),c=2*(a*n-o*i),f=2*(o*r-s*n);return this.x=n+l*u+s*f-a*c,this.y=r+l*c+a*u-o*f,this.z=i+l*f+o*c-s*u,this}project(e){return this.applyMatrix4(e.matrixWorldInverse).applyMatrix4(e.projectionMatrix)}unproject(e){return this.applyMatrix4(e.projectionMatrixInverse).applyMatrix4(e.matrixWorld)}transformDirection(e){let n=this.x,r=this.y,i=this.z,o=e.elements;return this.x=o[0]*n+o[4]*r+o[8]*i,this.y=o[1]*n+o[5]*r+o[9]*i,this.z=o[2]*n+o[6]*r+o[10]*i,this.normalize()}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this}divideScalar(e){return this.multiplyScalar(1/e)}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this}clamp(e,n){return this.x=Qe(this.x,e.x,n.x),this.y=Qe(this.y,e.y,n.y),this.z=Qe(this.z,e.z,n.z),this}clampScalar(e,n){return this.x=Qe(this.x,e,n),this.y=Qe(this.y,e,n),this.z=Qe(this.z,e,n),this}clampLength(e,n){let r=this.length();return this.divideScalar(r||1).multiplyScalar(Qe(r,e,n))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,n){return this.x+=(e.x-this.x)*n,this.y+=(e.y-this.y)*n,this.z+=(e.z-this.z)*n,this}lerpVectors(e,n,r){return this.x=e.x+(n.x-e.x)*r,this.y=e.y+(n.y-e.y)*r,this.z=e.z+(n.z-e.z)*r,this}cross(e){return this.crossVectors(this,e)}crossVectors(e,n){let r=e.x,i=e.y,o=e.z,s=n.x,a=n.y,l=n.z;return this.x=i*l-o*a,this.y=o*s-r*l,this.z=r*a-i*s,this}projectOnVector(e){let n=e.lengthSq();if(n===0)return this.set(0,0,0);let r=e.dot(this)/n;return this.copy(e).multiplyScalar(r)}projectOnPlane(e){return wf.copy(this).projectOnVector(e),this.sub(wf)}reflect(e){return this.sub(wf.copy(e).multiplyScalar(2*this.dot(e)))}angleTo(e){let n=Math.sqrt(this.lengthSq()*e.lengthSq());if(n===0)return Math.PI/2;let r=this.dot(e)/n;return Math.acos(Qe(r,-1,1))}distanceTo(e){return Math.sqrt(this.distanceToSquared(e))}distanceToSquared(e){let n=this.x-e.x,r=this.y-e.y,i=this.z-e.z;return n*n+r*r+i*i}manhattanDistanceTo(e){return Math.abs(this.x-e.x)+Math.abs(this.y-e.y)+Math.abs(this.z-e.z)}setFromSpherical(e){return this.setFromSphericalCoords(e.radius,e.phi,e.theta)}setFromSphericalCoords(e,n,r){let i=Math.sin(n)*e;return this.x=i*Math.sin(r),this.y=Math.cos(n)*e,this.z=i*Math.cos(r),this}setFromCylindrical(e){return this.setFromCylindricalCoords(e.radius,e.theta,e.y)}setFromCylindricalCoords(e,n,r){return this.x=e*Math.sin(n),this.y=r,this.z=e*Math.cos(n),this}setFromMatrixPosition(e){let n=e.elements;return this.x=n[12],this.y=n[13],this.z=n[14],this}setFromMatrixScale(e){let n=this.setFromMatrixColumn(e,0).length(),r=this.setFromMatrixColumn(e,1).length(),i=this.setFromMatrixColumn(e,2).length();return this.x=n,this.y=r,this.z=i,this}setFromMatrixColumn(e,n){return this.fromArray(e.elements,n*4)}setFromMatrix3Column(e,n){return this.fromArray(e.elements,n*3)}setFromEuler(e){return this.x=e._x,this.y=e._y,this.z=e._z,this}setFromColor(e){return this.x=e.r,this.y=e.g,this.z=e.b,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z}fromArray(e,n=0){return this.x=e[n],this.y=e[n+1],this.z=e[n+2],this}toArray(e=[],n=0){return e[n]=this.x,e[n+1]=this.y,e[n+2]=this.z,e}fromBufferAttribute(e,n){return this.x=e.getX(n),this.y=e.getY(n),this.z=e.getZ(n),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this}randomDirection(){let e=Math.random()*Math.PI*2,n=Math.random()*2-1,r=Math.sqrt(1-n*n);return this.x=r*Math.cos(e),this.y=n,this.z=r*Math.sin(e),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z}},wf=new k,Kp=new kn,Ke=class t{constructor(e,n,r,i,o,s,a,l,u){t.prototype.isMatrix3=!0,this.elements=[1,0,0,0,1,0,0,0,1],e!==void 0&&this.set(e,n,r,i,o,s,a,l,u)}set(e,n,r,i,o,s,a,l,u){let c=this.elements;return c[0]=e,c[1]=i,c[2]=a,c[3]=n,c[4]=o,c[5]=l,c[6]=r,c[7]=s,c[8]=u,this}identity(){return this.set(1,0,0,0,1,0,0,0,1),this}copy(e){let n=this.elements,r=e.elements;return n[0]=r[0],n[1]=r[1],n[2]=r[2],n[3]=r[3],n[4]=r[4],n[5]=r[5],n[6]=r[6],n[7]=r[7],n[8]=r[8],this}extractBasis(e,n,r){return e.setFromMatrix3Column(this,0),n.setFromMatrix3Column(this,1),r.setFromMatrix3Column(this,2),this}setFromMatrix4(e){let n=e.elements;return this.set(n[0],n[4],n[8],n[1],n[5],n[9],n[2],n[6],n[10]),this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,n){let r=e.elements,i=n.elements,o=this.elements,s=r[0],a=r[3],l=r[6],u=r[1],c=r[4],f=r[7],h=r[2],d=r[5],x=r[8],p=i[0],g=i[3],m=i[6],b=i[1],v=i[4],_=i[7],M=i[2],y=i[5],E=i[8];return o[0]=s*p+a*b+l*M,o[3]=s*g+a*v+l*y,o[6]=s*m+a*_+l*E,o[1]=u*p+c*b+f*M,o[4]=u*g+c*v+f*y,o[7]=u*m+c*_+f*E,o[2]=h*p+d*b+x*M,o[5]=h*g+d*v+x*y,o[8]=h*m+d*_+x*E,this}multiplyScalar(e){let n=this.elements;return n[0]*=e,n[3]*=e,n[6]*=e,n[1]*=e,n[4]*=e,n[7]*=e,n[2]*=e,n[5]*=e,n[8]*=e,this}determinant(){let e=this.elements,n=e[0],r=e[1],i=e[2],o=e[3],s=e[4],a=e[5],l=e[6],u=e[7],c=e[8];return n*s*c-n*a*u-r*o*c+r*a*l+i*o*u-i*s*l}invert(){let e=this.elements,n=e[0],r=e[1],i=e[2],o=e[3],s=e[4],a=e[5],l=e[6],u=e[7],c=e[8],f=c*s-a*u,h=a*l-c*o,d=u*o-s*l,x=n*f+r*h+i*d;if(x===0)return this.set(0,0,0,0,0,0,0,0,0);let p=1/x;return e[0]=f*p,e[1]=(i*u-c*r)*p,e[2]=(a*r-i*s)*p,e[3]=h*p,e[4]=(c*n-i*l)*p,e[5]=(i*o-a*n)*p,e[6]=d*p,e[7]=(r*l-u*n)*p,e[8]=(s*n-r*o)*p,this}transpose(){let e,n=this.elements;return e=n[1],n[1]=n[3],n[3]=e,e=n[2],n[2]=n[6],n[6]=e,e=n[5],n[5]=n[7],n[7]=e,this}getNormalMatrix(e){return this.setFromMatrix4(e).invert().transpose()}transposeIntoArray(e){let n=this.elements;return e[0]=n[0],e[1]=n[3],e[2]=n[6],e[3]=n[1],e[4]=n[4],e[5]=n[7],e[6]=n[2],e[7]=n[5],e[8]=n[8],this}setUvTransform(e,n,r,i,o,s,a){let l=Math.cos(o),u=Math.sin(o);return this.set(r*l,r*u,-r*(l*s+u*a)+s+e,-i*u,i*l,-i*(-u*s+l*a)+a+n,0,0,1),this}scale(e,n){return this.premultiply(bf.makeScale(e,n)),this}rotate(e){return this.premultiply(bf.makeRotation(-e)),this}translate(e,n){return this.premultiply(bf.makeTranslation(e,n)),this}makeTranslation(e,n){return e.isVector2?this.set(1,0,e.x,0,1,e.y,0,0,1):this.set(1,0,e,0,1,n,0,0,1),this}makeRotation(e){let n=Math.cos(e),r=Math.sin(e);return this.set(n,-r,0,r,n,0,0,0,1),this}makeScale(e,n){return this.set(e,0,0,0,n,0,0,0,1),this}equals(e){let n=this.elements,r=e.elements;for(let i=0;i<9;i++)if(n[i]!==r[i])return!1;return!0}fromArray(e,n=0){for(let r=0;r<9;r++)this.elements[r]=e[r+n];return this}toArray(e=[],n=0){let r=this.elements;return e[n]=r[0],e[n+1]=r[1],e[n+2]=r[2],e[n+3]=r[3],e[n+4]=r[4],e[n+5]=r[5],e[n+6]=r[6],e[n+7]=r[7],e[n+8]=r[8],e}clone(){return new this.constructor().fromArray(this.elements)}},bf=new Ke;function bh(t){for(let e=t.length-1;e>=0;--e)if(t[e]>=65535)return!0;return!1}function ws(t){return document.createElementNS("http://www.w3.org/1999/xhtml",t)}function ag(){let t=ws("canvas");return t.style.display="block",t}var Qp={};function Eo(t){t in Qp||(Qp[t]=!0,console.warn(t))}function ug(t,e,n){return new Promise(function(r,i){function o(){switch(t.clientWaitSync(e,t.SYNC_FLUSH_COMMANDS_BIT,0)){case t.WAIT_FAILED:i();break;case t.TIMEOUT_EXPIRED:setTimeout(o,n);break;default:r()}}setTimeout(o,n)})}var jp=new Ke().set(.4123908,.3575843,.1804808,.212639,.7151687,.0721923,.0193308,.1191948,.9505322),em=new Ke().set(3.2409699,-1.5373832,-.4986108,-.9692436,1.8759675,.0415551,.0556301,-.203977,1.0569715);function Py(){let t={enabled:!0,workingColorSpace:Ai,spaces:{},convert:function(i,o,s){return this.enabled===!1||o===s||!o||!s||(this.spaces[o].transfer===gt&&(i.r=Dr(i.r),i.g=Dr(i.g),i.b=Dr(i.b)),this.spaces[o].primaries!==this.spaces[s].primaries&&(i.applyMatrix3(this.spaces[o].toXYZ),i.applyMatrix3(this.spaces[s].fromXYZ)),this.spaces[s].transfer===gt&&(i.r=So(i.r),i.g=So(i.g),i.b=So(i.b))),i},workingToColorSpace:function(i,o){return this.convert(i,this.workingColorSpace,o)},colorSpaceToWorking:function(i,o){return this.convert(i,o,this.workingColorSpace)},getPrimaries:function(i){return this.spaces[i].primaries},getTransfer:function(i){return i===Fr?Ms:this.spaces[i].transfer},getToneMappingMode:function(i){return this.spaces[i].outputColorSpaceConfig.toneMappingMode||"standard"},getLuminanceCoefficients:function(i,o=this.workingColorSpace){return i.fromArray(this.spaces[o].luminanceCoefficients)},define:function(i){Object.assign(this.spaces,i)},_getMatrix:function(i,o,s){return i.copy(this.spaces[o].toXYZ).multiply(this.spaces[s].fromXYZ)},_getDrawingBufferColorSpace:function(i){return this.spaces[i].outputColorSpaceConfig.drawingBufferColorSpace},_getUnpackColorSpace:function(i=this.workingColorSpace){return this.spaces[i].workingColorSpaceConfig.unpackColorSpace},fromWorkingColorSpace:function(i,o){return Eo("THREE.ColorManagement: .fromWorkingColorSpace() has been renamed to .workingToColorSpace()."),t.workingToColorSpace(i,o)},toWorkingColorSpace:function(i,o){return Eo("THREE.ColorManagement: .toWorkingColorSpace() has been renamed to .colorSpaceToWorking()."),t.colorSpaceToWorking(i,o)}},e=[.64,.33,.3,.6,.15,.06],n=[.2126,.7152,.0722],r=[.3127,.329];return t.define({[Ai]:{primaries:e,whitePoint:r,transfer:Ms,toXYZ:jp,fromXYZ:em,luminanceCoefficients:n,workingColorSpaceConfig:{unpackColorSpace:An},outputColorSpaceConfig:{drawingBufferColorSpace:An}},[An]:{primaries:e,whitePoint:r,transfer:gt,toXYZ:jp,fromXYZ:em,luminanceCoefficients:n,outputColorSpaceConfig:{drawingBufferColorSpace:An}}}),t}var ct=Py();function Dr(t){return t<.04045?t*.0773993808:Math.pow(t*.9478672986+.0521327014,2.4)}function So(t){return t<.0031308?t*12.92:1.055*Math.pow(t,.41666)-.055}var uo,au=class{static getDataURL(e,n="image/png"){if(/^data:/i.test(e.src)||typeof HTMLCanvasElement>"u")return e.src;let r;if(e instanceof HTMLCanvasElement)r=e;else{uo===void 0&&(uo=ws("canvas")),uo.width=e.width,uo.height=e.height;let i=uo.getContext("2d");e instanceof ImageData?i.putImageData(e,0,0):i.drawImage(e,0,0,e.width,e.height),r=uo}return r.toDataURL(n)}static sRGBToLinear(e){if(typeof HTMLImageElement<"u"&&e instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&e instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&e instanceof ImageBitmap){let n=ws("canvas");n.width=e.width,n.height=e.height;let r=n.getContext("2d");r.drawImage(e,0,0,e.width,e.height);let i=r.getImageData(0,0,e.width,e.height),o=i.data;for(let s=0;s<o.length;s++)o[s]=Dr(o[s]/255)*255;return r.putImageData(i,0,0),n}else if(e.data){let n=e.data.slice(0);for(let r=0;r<n.length;r++)n instanceof Uint8Array||n instanceof Uint8ClampedArray?n[r]=Math.floor(Dr(n[r]/255)*255):n[r]=Dr(n[r]);return{data:n,width:e.width,height:e.height}}else return console.warn("THREE.ImageUtils.sRGBToLinear(): Unsupported image type. No color space conversion applied."),e}},Iy=0,Do=class{constructor(e=null){this.isSource=!0,Object.defineProperty(this,"id",{value:Iy++}),this.uuid=Oo(),this.data=e,this.dataReady=!0,this.version=0}getSize(e){let n=this.data;return typeof HTMLVideoElement<"u"&&n instanceof HTMLVideoElement?e.set(n.videoWidth,n.videoHeight,0):n instanceof VideoFrame?e.set(n.displayHeight,n.displayWidth,0):n!==null?e.set(n.width,n.height,n.depth||0):e.set(0,0,0),e}set needsUpdate(e){e===!0&&this.version++}toJSON(e){let n=e===void 0||typeof e=="string";if(!n&&e.images[this.uuid]!==void 0)return e.images[this.uuid];let r={uuid:this.uuid,url:""},i=this.data;if(i!==null){let o;if(Array.isArray(i)){o=[];for(let s=0,a=i.length;s<a;s++)i[s].isDataTexture?o.push(Ef(i[s].image)):o.push(Ef(i[s]))}else o=Ef(i);r.url=o}return n||(e.images[this.uuid]=r),r}};function Ef(t){return typeof HTMLImageElement<"u"&&t instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&t instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&t instanceof ImageBitmap?au.getDataURL(t):t.data?{data:Array.from(t.data),width:t.width,height:t.height,type:t.data.constructor.name}:(console.warn("THREE.Texture: Unable to serialize Texture."),{})}var Ny=0,Df=new k,Tn=class t extends ur{constructor(e=t.DEFAULT_IMAGE,n=t.DEFAULT_MAPPING,r=Zr,i=Zr,o=Jn,s=ti,a=Hn,l=er,u=t.DEFAULT_ANISOTROPY,c=Fr){super(),this.isTexture=!0,Object.defineProperty(this,"id",{value:Ny++}),this.uuid=Oo(),this.name="",this.source=new Do(e),this.mipmaps=[],this.mapping=n,this.channel=0,this.wrapS=r,this.wrapT=i,this.magFilter=o,this.minFilter=s,this.anisotropy=u,this.format=a,this.internalFormat=null,this.type=l,this.offset=new Ie(0,0),this.repeat=new Ie(1,1),this.center=new Ie(0,0),this.rotation=0,this.matrixAutoUpdate=!0,this.matrix=new Ke,this.generateMipmaps=!0,this.premultiplyAlpha=!1,this.flipY=!0,this.unpackAlignment=4,this.colorSpace=c,this.userData={},this.updateRanges=[],this.version=0,this.onUpdate=null,this.renderTarget=null,this.isRenderTargetTexture=!1,this.isArrayTexture=!!(e&&e.depth&&e.depth>1),this.pmremVersion=0}get width(){return this.source.getSize(Df).x}get height(){return this.source.getSize(Df).y}get depth(){return this.source.getSize(Df).z}get image(){return this.source.data}set image(e=null){this.source.data=e}updateMatrix(){this.matrix.setUvTransform(this.offset.x,this.offset.y,this.repeat.x,this.repeat.y,this.rotation,this.center.x,this.center.y)}addUpdateRange(e,n){this.updateRanges.push({start:e,count:n})}clearUpdateRanges(){this.updateRanges.length=0}clone(){return new this.constructor().copy(this)}copy(e){return this.name=e.name,this.source=e.source,this.mipmaps=e.mipmaps.slice(0),this.mapping=e.mapping,this.channel=e.channel,this.wrapS=e.wrapS,this.wrapT=e.wrapT,this.magFilter=e.magFilter,this.minFilter=e.minFilter,this.anisotropy=e.anisotropy,this.format=e.format,this.internalFormat=e.internalFormat,this.type=e.type,this.offset.copy(e.offset),this.repeat.copy(e.repeat),this.center.copy(e.center),this.rotation=e.rotation,this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrix.copy(e.matrix),this.generateMipmaps=e.generateMipmaps,this.premultiplyAlpha=e.premultiplyAlpha,this.flipY=e.flipY,this.unpackAlignment=e.unpackAlignment,this.colorSpace=e.colorSpace,this.renderTarget=e.renderTarget,this.isRenderTargetTexture=e.isRenderTargetTexture,this.isArrayTexture=e.isArrayTexture,this.userData=JSON.parse(JSON.stringify(e.userData)),this.needsUpdate=!0,this}setValues(e){for(let n in e){let r=e[n];if(r===void 0){console.warn(`THREE.Texture.setValues(): parameter '${n}' has value of undefined.`);continue}let i=this[n];if(i===void 0){console.warn(`THREE.Texture.setValues(): property '${n}' does not exist.`);continue}i&&r&&i.isVector2&&r.isVector2||i&&r&&i.isVector3&&r.isVector3||i&&r&&i.isMatrix3&&r.isMatrix3?i.copy(r):this[n]=r}}toJSON(e){let n=e===void 0||typeof e=="string";if(!n&&e.textures[this.uuid]!==void 0)return e.textures[this.uuid];let r={metadata:{version:4.7,type:"Texture",generator:"Texture.toJSON"},uuid:this.uuid,name:this.name,image:this.source.toJSON(e).uuid,mapping:this.mapping,channel:this.channel,repeat:[this.repeat.x,this.repeat.y],offset:[this.offset.x,this.offset.y],center:[this.center.x,this.center.y],rotation:this.rotation,wrap:[this.wrapS,this.wrapT],format:this.format,internalFormat:this.internalFormat,type:this.type,colorSpace:this.colorSpace,minFilter:this.minFilter,magFilter:this.magFilter,anisotropy:this.anisotropy,flipY:this.flipY,generateMipmaps:this.generateMipmaps,premultiplyAlpha:this.premultiplyAlpha,unpackAlignment:this.unpackAlignment};return Object.keys(this.userData).length>0&&(r.userData=this.userData),n||(e.textures[this.uuid]=r),r}dispose(){this.dispatchEvent({type:"dispose"})}transformUv(e){if(this.mapping!==ch)return e;if(e.applyMatrix3(this.matrix),e.x<0||e.x>1)switch(this.wrapS){case iu:e.x=e.x-Math.floor(e.x);break;case Zr:e.x=e.x<0?0:1;break;case ou:Math.abs(Math.floor(e.x)%2)===1?e.x=Math.ceil(e.x)-e.x:e.x=e.x-Math.floor(e.x);break}if(e.y<0||e.y>1)switch(this.wrapT){case iu:e.y=e.y-Math.floor(e.y);break;case Zr:e.y=e.y<0?0:1;break;case ou:Math.abs(Math.floor(e.y)%2)===1?e.y=Math.ceil(e.y)-e.y:e.y=e.y-Math.floor(e.y);break}return this.flipY&&(e.y=1-e.y),e}set needsUpdate(e){e===!0&&(this.version++,this.source.needsUpdate=!0)}set needsPMREMUpdate(e){e===!0&&this.pmremVersion++}};Tn.DEFAULT_IMAGE=null;Tn.DEFAULT_MAPPING=ch;Tn.DEFAULT_ANISOTROPY=1;var Ft=class t{constructor(e=0,n=0,r=0,i=1){t.prototype.isVector4=!0,this.x=e,this.y=n,this.z=r,this.w=i}get width(){return this.z}set width(e){this.z=e}get height(){return this.w}set height(e){this.w=e}set(e,n,r,i){return this.x=e,this.y=n,this.z=r,this.w=i,this}setScalar(e){return this.x=e,this.y=e,this.z=e,this.w=e,this}setX(e){return this.x=e,this}setY(e){return this.y=e,this}setZ(e){return this.z=e,this}setW(e){return this.w=e,this}setComponent(e,n){switch(e){case 0:this.x=n;break;case 1:this.y=n;break;case 2:this.z=n;break;case 3:this.w=n;break;default:throw new Error("index is out of range: "+e)}return this}getComponent(e){switch(e){case 0:return this.x;case 1:return this.y;case 2:return this.z;case 3:return this.w;default:throw new Error("index is out of range: "+e)}}clone(){return new this.constructor(this.x,this.y,this.z,this.w)}copy(e){return this.x=e.x,this.y=e.y,this.z=e.z,this.w=e.w!==void 0?e.w:1,this}add(e){return this.x+=e.x,this.y+=e.y,this.z+=e.z,this.w+=e.w,this}addScalar(e){return this.x+=e,this.y+=e,this.z+=e,this.w+=e,this}addVectors(e,n){return this.x=e.x+n.x,this.y=e.y+n.y,this.z=e.z+n.z,this.w=e.w+n.w,this}addScaledVector(e,n){return this.x+=e.x*n,this.y+=e.y*n,this.z+=e.z*n,this.w+=e.w*n,this}sub(e){return this.x-=e.x,this.y-=e.y,this.z-=e.z,this.w-=e.w,this}subScalar(e){return this.x-=e,this.y-=e,this.z-=e,this.w-=e,this}subVectors(e,n){return this.x=e.x-n.x,this.y=e.y-n.y,this.z=e.z-n.z,this.w=e.w-n.w,this}multiply(e){return this.x*=e.x,this.y*=e.y,this.z*=e.z,this.w*=e.w,this}multiplyScalar(e){return this.x*=e,this.y*=e,this.z*=e,this.w*=e,this}applyMatrix4(e){let n=this.x,r=this.y,i=this.z,o=this.w,s=e.elements;return this.x=s[0]*n+s[4]*r+s[8]*i+s[12]*o,this.y=s[1]*n+s[5]*r+s[9]*i+s[13]*o,this.z=s[2]*n+s[6]*r+s[10]*i+s[14]*o,this.w=s[3]*n+s[7]*r+s[11]*i+s[15]*o,this}divide(e){return this.x/=e.x,this.y/=e.y,this.z/=e.z,this.w/=e.w,this}divideScalar(e){return this.multiplyScalar(1/e)}setAxisAngleFromQuaternion(e){this.w=2*Math.acos(e.w);let n=Math.sqrt(1-e.w*e.w);return n<1e-4?(this.x=1,this.y=0,this.z=0):(this.x=e.x/n,this.y=e.y/n,this.z=e.z/n),this}setAxisAngleFromRotationMatrix(e){let n,r,i,o,l=e.elements,u=l[0],c=l[4],f=l[8],h=l[1],d=l[5],x=l[9],p=l[2],g=l[6],m=l[10];if(Math.abs(c-h)<.01&&Math.abs(f-p)<.01&&Math.abs(x-g)<.01){if(Math.abs(c+h)<.1&&Math.abs(f+p)<.1&&Math.abs(x+g)<.1&&Math.abs(u+d+m-3)<.1)return this.set(1,0,0,0),this;n=Math.PI;let v=(u+1)/2,_=(d+1)/2,M=(m+1)/2,y=(c+h)/4,E=(f+p)/4,D=(x+g)/4;return v>_&&v>M?v<.01?(r=0,i=.707106781,o=.707106781):(r=Math.sqrt(v),i=y/r,o=E/r):_>M?_<.01?(r=.707106781,i=0,o=.707106781):(i=Math.sqrt(_),r=y/i,o=D/i):M<.01?(r=.707106781,i=.707106781,o=0):(o=Math.sqrt(M),r=E/o,i=D/o),this.set(r,i,o,n),this}let b=Math.sqrt((g-x)*(g-x)+(f-p)*(f-p)+(h-c)*(h-c));return Math.abs(b)<.001&&(b=1),this.x=(g-x)/b,this.y=(f-p)/b,this.z=(h-c)/b,this.w=Math.acos((u+d+m-1)/2),this}setFromMatrixPosition(e){let n=e.elements;return this.x=n[12],this.y=n[13],this.z=n[14],this.w=n[15],this}min(e){return this.x=Math.min(this.x,e.x),this.y=Math.min(this.y,e.y),this.z=Math.min(this.z,e.z),this.w=Math.min(this.w,e.w),this}max(e){return this.x=Math.max(this.x,e.x),this.y=Math.max(this.y,e.y),this.z=Math.max(this.z,e.z),this.w=Math.max(this.w,e.w),this}clamp(e,n){return this.x=Qe(this.x,e.x,n.x),this.y=Qe(this.y,e.y,n.y),this.z=Qe(this.z,e.z,n.z),this.w=Qe(this.w,e.w,n.w),this}clampScalar(e,n){return this.x=Qe(this.x,e,n),this.y=Qe(this.y,e,n),this.z=Qe(this.z,e,n),this.w=Qe(this.w,e,n),this}clampLength(e,n){let r=this.length();return this.divideScalar(r||1).multiplyScalar(Qe(r,e,n))}floor(){return this.x=Math.floor(this.x),this.y=Math.floor(this.y),this.z=Math.floor(this.z),this.w=Math.floor(this.w),this}ceil(){return this.x=Math.ceil(this.x),this.y=Math.ceil(this.y),this.z=Math.ceil(this.z),this.w=Math.ceil(this.w),this}round(){return this.x=Math.round(this.x),this.y=Math.round(this.y),this.z=Math.round(this.z),this.w=Math.round(this.w),this}roundToZero(){return this.x=Math.trunc(this.x),this.y=Math.trunc(this.y),this.z=Math.trunc(this.z),this.w=Math.trunc(this.w),this}negate(){return this.x=-this.x,this.y=-this.y,this.z=-this.z,this.w=-this.w,this}dot(e){return this.x*e.x+this.y*e.y+this.z*e.z+this.w*e.w}lengthSq(){return this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w}length(){return Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w)}manhattanLength(){return Math.abs(this.x)+Math.abs(this.y)+Math.abs(this.z)+Math.abs(this.w)}normalize(){return this.divideScalar(this.length()||1)}setLength(e){return this.normalize().multiplyScalar(e)}lerp(e,n){return this.x+=(e.x-this.x)*n,this.y+=(e.y-this.y)*n,this.z+=(e.z-this.z)*n,this.w+=(e.w-this.w)*n,this}lerpVectors(e,n,r){return this.x=e.x+(n.x-e.x)*r,this.y=e.y+(n.y-e.y)*r,this.z=e.z+(n.z-e.z)*r,this.w=e.w+(n.w-e.w)*r,this}equals(e){return e.x===this.x&&e.y===this.y&&e.z===this.z&&e.w===this.w}fromArray(e,n=0){return this.x=e[n],this.y=e[n+1],this.z=e[n+2],this.w=e[n+3],this}toArray(e=[],n=0){return e[n]=this.x,e[n+1]=this.y,e[n+2]=this.z,e[n+3]=this.w,e}fromBufferAttribute(e,n){return this.x=e.getX(n),this.y=e.getY(n),this.z=e.getZ(n),this.w=e.getW(n),this}random(){return this.x=Math.random(),this.y=Math.random(),this.z=Math.random(),this.w=Math.random(),this}*[Symbol.iterator](){yield this.x,yield this.y,yield this.z,yield this.w}},uu=class extends ur{constructor(e=1,n=1,r={}){super(),r=Object.assign({generateMipmaps:!1,internalFormat:null,minFilter:Jn,depthBuffer:!0,stencilBuffer:!1,resolveDepthBuffer:!0,resolveStencilBuffer:!0,depthTexture:null,samples:0,count:1,depth:1,multiview:!1},r),this.isRenderTarget=!0,this.width=e,this.height=n,this.depth=r.depth,this.scissor=new Ft(0,0,e,n),this.scissorTest=!1,this.viewport=new Ft(0,0,e,n);let i={width:e,height:n,depth:r.depth},o=new Tn(i);this.textures=[];let s=r.count;for(let a=0;a<s;a++)this.textures[a]=o.clone(),this.textures[a].isRenderTargetTexture=!0,this.textures[a].renderTarget=this;this._setTextureOptions(r),this.depthBuffer=r.depthBuffer,this.stencilBuffer=r.stencilBuffer,this.resolveDepthBuffer=r.resolveDepthBuffer,this.resolveStencilBuffer=r.resolveStencilBuffer,this._depthTexture=null,this.depthTexture=r.depthTexture,this.samples=r.samples,this.multiview=r.multiview}_setTextureOptions(e={}){let n={minFilter:Jn,generateMipmaps:!1,flipY:!1,internalFormat:null};e.mapping!==void 0&&(n.mapping=e.mapping),e.wrapS!==void 0&&(n.wrapS=e.wrapS),e.wrapT!==void 0&&(n.wrapT=e.wrapT),e.wrapR!==void 0&&(n.wrapR=e.wrapR),e.magFilter!==void 0&&(n.magFilter=e.magFilter),e.minFilter!==void 0&&(n.minFilter=e.minFilter),e.format!==void 0&&(n.format=e.format),e.type!==void 0&&(n.type=e.type),e.anisotropy!==void 0&&(n.anisotropy=e.anisotropy),e.colorSpace!==void 0&&(n.colorSpace=e.colorSpace),e.flipY!==void 0&&(n.flipY=e.flipY),e.generateMipmaps!==void 0&&(n.generateMipmaps=e.generateMipmaps),e.internalFormat!==void 0&&(n.internalFormat=e.internalFormat);for(let r=0;r<this.textures.length;r++)this.textures[r].setValues(n)}get texture(){return this.textures[0]}set texture(e){this.textures[0]=e}set depthTexture(e){this._depthTexture!==null&&(this._depthTexture.renderTarget=null),e!==null&&(e.renderTarget=this),this._depthTexture=e}get depthTexture(){return this._depthTexture}setSize(e,n,r=1){if(this.width!==e||this.height!==n||this.depth!==r){this.width=e,this.height=n,this.depth=r;for(let i=0,o=this.textures.length;i<o;i++)this.textures[i].image.width=e,this.textures[i].image.height=n,this.textures[i].image.depth=r,this.textures[i].isArrayTexture=this.textures[i].image.depth>1;this.dispose()}this.viewport.set(0,0,e,n),this.scissor.set(0,0,e,n)}clone(){return new this.constructor().copy(this)}copy(e){this.width=e.width,this.height=e.height,this.depth=e.depth,this.scissor.copy(e.scissor),this.scissorTest=e.scissorTest,this.viewport.copy(e.viewport),this.textures.length=0;for(let n=0,r=e.textures.length;n<r;n++){this.textures[n]=e.textures[n].clone(),this.textures[n].isRenderTargetTexture=!0,this.textures[n].renderTarget=this;let i=Object.assign({},e.textures[n].image);this.textures[n].source=new Do(i)}return this.depthBuffer=e.depthBuffer,this.stencilBuffer=e.stencilBuffer,this.resolveDepthBuffer=e.resolveDepthBuffer,this.resolveStencilBuffer=e.resolveStencilBuffer,e.depthTexture!==null&&(this.depthTexture=e.depthTexture.clone()),this.samples=e.samples,this}dispose(){this.dispatchEvent({type:"dispose"})}},lr=class extends uu{constructor(e=1,n=1,r={}){super(e,n,r),this.isWebGLRenderTarget=!0}},bs=class extends Tn{constructor(e=null,n=1,r=1,i=1){super(null),this.isDataArrayTexture=!0,this.image={data:e,width:n,height:r,depth:i},this.magFilter=zn,this.minFilter=zn,this.wrapR=Zr,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1,this.layerUpdates=new Set}addLayerUpdate(e){this.layerUpdates.add(e)}clearLayerUpdates(){this.layerUpdates.clear()}};var lu=class extends Tn{constructor(e=null,n=1,r=1,i=1){super(null),this.isData3DTexture=!0,this.image={data:e,width:n,height:r,depth:i},this.magFilter=zn,this.minFilter=zn,this.wrapR=Zr,this.generateMipmaps=!1,this.flipY=!1,this.unpackAlignment=1}};var Jr=class{constructor(e=new k(1/0,1/0,1/0),n=new k(-1/0,-1/0,-1/0)){this.isBox3=!0,this.min=e,this.max=n}set(e,n){return this.min.copy(e),this.max.copy(n),this}setFromArray(e){this.makeEmpty();for(let n=0,r=e.length;n<r;n+=3)this.expandByPoint(Xn.fromArray(e,n));return this}setFromBufferAttribute(e){this.makeEmpty();for(let n=0,r=e.count;n<r;n++)this.expandByPoint(Xn.fromBufferAttribute(e,n));return this}setFromPoints(e){this.makeEmpty();for(let n=0,r=e.length;n<r;n++)this.expandByPoint(e[n]);return this}setFromCenterAndSize(e,n){let r=Xn.copy(n).multiplyScalar(.5);return this.min.copy(e).sub(r),this.max.copy(e).add(r),this}setFromObject(e,n=!1){return this.makeEmpty(),this.expandByObject(e,n)}clone(){return new this.constructor().copy(this)}copy(e){return this.min.copy(e.min),this.max.copy(e.max),this}makeEmpty(){return this.min.x=this.min.y=this.min.z=1/0,this.max.x=this.max.y=this.max.z=-1/0,this}isEmpty(){return this.max.x<this.min.x||this.max.y<this.min.y||this.max.z<this.min.z}getCenter(e){return this.isEmpty()?e.set(0,0,0):e.addVectors(this.min,this.max).multiplyScalar(.5)}getSize(e){return this.isEmpty()?e.set(0,0,0):e.subVectors(this.max,this.min)}expandByPoint(e){return this.min.min(e),this.max.max(e),this}expandByVector(e){return this.min.sub(e),this.max.add(e),this}expandByScalar(e){return this.min.addScalar(-e),this.max.addScalar(e),this}expandByObject(e,n=!1){e.updateWorldMatrix(!1,!1);let r=e.geometry;if(r!==void 0){let o=r.getAttribute("position");if(n===!0&&o!==void 0&&e.isInstancedMesh!==!0)for(let s=0,a=o.count;s<a;s++)e.isMesh===!0?e.getVertexPosition(s,Xn):Xn.fromBufferAttribute(o,s),Xn.applyMatrix4(e.matrixWorld),this.expandByPoint(Xn);else e.boundingBox!==void 0?(e.boundingBox===null&&e.computeBoundingBox(),Ia.copy(e.boundingBox)):(r.boundingBox===null&&r.computeBoundingBox(),Ia.copy(r.boundingBox)),Ia.applyMatrix4(e.matrixWorld),this.union(Ia)}let i=e.children;for(let o=0,s=i.length;o<s;o++)this.expandByObject(i[o],n);return this}containsPoint(e){return e.x>=this.min.x&&e.x<=this.max.x&&e.y>=this.min.y&&e.y<=this.max.y&&e.z>=this.min.z&&e.z<=this.max.z}containsBox(e){return this.min.x<=e.min.x&&e.max.x<=this.max.x&&this.min.y<=e.min.y&&e.max.y<=this.max.y&&this.min.z<=e.min.z&&e.max.z<=this.max.z}getParameter(e,n){return n.set((e.x-this.min.x)/(this.max.x-this.min.x),(e.y-this.min.y)/(this.max.y-this.min.y),(e.z-this.min.z)/(this.max.z-this.min.z))}intersectsBox(e){return e.max.x>=this.min.x&&e.min.x<=this.max.x&&e.max.y>=this.min.y&&e.min.y<=this.max.y&&e.max.z>=this.min.z&&e.min.z<=this.max.z}intersectsSphere(e){return this.clampPoint(e.center,Xn),Xn.distanceToSquared(e.center)<=e.radius*e.radius}intersectsPlane(e){let n,r;return e.normal.x>0?(n=e.normal.x*this.min.x,r=e.normal.x*this.max.x):(n=e.normal.x*this.max.x,r=e.normal.x*this.min.x),e.normal.y>0?(n+=e.normal.y*this.min.y,r+=e.normal.y*this.max.y):(n+=e.normal.y*this.max.y,r+=e.normal.y*this.min.y),e.normal.z>0?(n+=e.normal.z*this.min.z,r+=e.normal.z*this.max.z):(n+=e.normal.z*this.max.z,r+=e.normal.z*this.min.z),n<=-e.constant&&r>=-e.constant}intersectsTriangle(e){if(this.isEmpty())return!1;this.getCenter(fs),Na.subVectors(this.max,fs),lo.subVectors(e.a,fs),co.subVectors(e.b,fs),fo.subVectors(e.c,fs),Vr.subVectors(co,lo),Hr.subVectors(fo,co),yi.subVectors(lo,fo);let n=[0,-Vr.z,Vr.y,0,-Hr.z,Hr.y,0,-yi.z,yi.y,Vr.z,0,-Vr.x,Hr.z,0,-Hr.x,yi.z,0,-yi.x,-Vr.y,Vr.x,0,-Hr.y,Hr.x,0,-yi.y,yi.x,0];return!Af(n,lo,co,fo,Na)||(n=[1,0,0,0,1,0,0,0,1],!Af(n,lo,co,fo,Na))?!1:(La.crossVectors(Vr,Hr),n=[La.x,La.y,La.z],Af(n,lo,co,fo,Na))}clampPoint(e,n){return n.copy(e).clamp(this.min,this.max)}distanceToPoint(e){return this.clampPoint(e,Xn).distanceTo(e)}getBoundingSphere(e){return this.isEmpty()?e.makeEmpty():(this.getCenter(e.center),e.radius=this.getSize(Xn).length()*.5),e}intersect(e){return this.min.max(e.min),this.max.min(e.max),this.isEmpty()&&this.makeEmpty(),this}union(e){return this.min.min(e.min),this.max.max(e.max),this}applyMatrix4(e){return this.isEmpty()?this:(yr[0].set(this.min.x,this.min.y,this.min.z).applyMatrix4(e),yr[1].set(this.min.x,this.min.y,this.max.z).applyMatrix4(e),yr[2].set(this.min.x,this.max.y,this.min.z).applyMatrix4(e),yr[3].set(this.min.x,this.max.y,this.max.z).applyMatrix4(e),yr[4].set(this.max.x,this.min.y,this.min.z).applyMatrix4(e),yr[5].set(this.max.x,this.min.y,this.max.z).applyMatrix4(e),yr[6].set(this.max.x,this.max.y,this.min.z).applyMatrix4(e),yr[7].set(this.max.x,this.max.y,this.max.z).applyMatrix4(e),this.setFromPoints(yr),this)}translate(e){return this.min.add(e),this.max.add(e),this}equals(e){return e.min.equals(this.min)&&e.max.equals(this.max)}toJSON(){return{min:this.min.toArray(),max:this.max.toArray()}}fromJSON(e){return this.min.fromArray(e.min),this.max.fromArray(e.max),this}},yr=[new k,new k,new k,new k,new k,new k,new k,new k],Xn=new k,Ia=new Jr,lo=new k,co=new k,fo=new k,Vr=new k,Hr=new k,yi=new k,fs=new k,Na=new k,La=new k,Mi=new k;function Af(t,e,n,r,i){for(let o=0,s=t.length-3;o<=s;o+=3){Mi.fromArray(t,o);let a=i.x*Math.abs(Mi.x)+i.y*Math.abs(Mi.y)+i.z*Math.abs(Mi.z),l=e.dot(Mi),u=n.dot(Mi),c=r.dot(Mi);if(Math.max(-Math.max(l,u,c),Math.min(l,u,c))>a)return!1}return!0}var Ly=new Jr,hs=new k,Cf=new k,Ci=class{constructor(e=new k,n=-1){this.isSphere=!0,this.center=e,this.radius=n}set(e,n){return this.center.copy(e),this.radius=n,this}setFromPoints(e,n){let r=this.center;n!==void 0?r.copy(n):Ly.setFromPoints(e).getCenter(r);let i=0;for(let o=0,s=e.length;o<s;o++)i=Math.max(i,r.distanceToSquared(e[o]));return this.radius=Math.sqrt(i),this}copy(e){return this.center.copy(e.center),this.radius=e.radius,this}isEmpty(){return this.radius<0}makeEmpty(){return this.center.set(0,0,0),this.radius=-1,this}containsPoint(e){return e.distanceToSquared(this.center)<=this.radius*this.radius}distanceToPoint(e){return e.distanceTo(this.center)-this.radius}intersectsSphere(e){let n=this.radius+e.radius;return e.center.distanceToSquared(this.center)<=n*n}intersectsBox(e){return e.intersectsSphere(this)}intersectsPlane(e){return Math.abs(e.distanceToPoint(this.center))<=this.radius}clampPoint(e,n){let r=this.center.distanceToSquared(e);return n.copy(e),r>this.radius*this.radius&&(n.sub(this.center).normalize(),n.multiplyScalar(this.radius).add(this.center)),n}getBoundingBox(e){return this.isEmpty()?(e.makeEmpty(),e):(e.set(this.center,this.center),e.expandByScalar(this.radius),e)}applyMatrix4(e){return this.center.applyMatrix4(e),this.radius=this.radius*e.getMaxScaleOnAxis(),this}translate(e){return this.center.add(e),this}expandByPoint(e){if(this.isEmpty())return this.center.copy(e),this.radius=0,this;hs.subVectors(e,this.center);let n=hs.lengthSq();if(n>this.radius*this.radius){let r=Math.sqrt(n),i=(r-this.radius)*.5;this.center.addScaledVector(hs,i/r),this.radius+=i}return this}union(e){return e.isEmpty()?this:this.isEmpty()?(this.copy(e),this):(this.center.equals(e.center)===!0?this.radius=Math.max(this.radius,e.radius):(Cf.subVectors(e.center,this.center).setLength(e.radius),this.expandByPoint(hs.copy(e.center).add(Cf)),this.expandByPoint(hs.copy(e.center).sub(Cf))),this)}equals(e){return e.center.equals(this.center)&&e.radius===this.radius}clone(){return new this.constructor().copy(this)}toJSON(){return{radius:this.radius,center:this.center.toArray()}}fromJSON(e){return this.radius=e.radius,this.center.fromArray(e.center),this}},Mr=new k,Tf=new k,Ba=new k,Gr=new k,Rf=new k,Ua=new k,Ff=new k,Ti=class{constructor(e=new k,n=new k(0,0,-1)){this.origin=e,this.direction=n}set(e,n){return this.origin.copy(e),this.direction.copy(n),this}copy(e){return this.origin.copy(e.origin),this.direction.copy(e.direction),this}at(e,n){return n.copy(this.origin).addScaledVector(this.direction,e)}lookAt(e){return this.direction.copy(e).sub(this.origin).normalize(),this}recast(e){return this.origin.copy(this.at(e,Mr)),this}closestPointToPoint(e,n){n.subVectors(e,this.origin);let r=n.dot(this.direction);return r<0?n.copy(this.origin):n.copy(this.origin).addScaledVector(this.direction,r)}distanceToPoint(e){return Math.sqrt(this.distanceSqToPoint(e))}distanceSqToPoint(e){let n=Mr.subVectors(e,this.origin).dot(this.direction);return n<0?this.origin.distanceToSquared(e):(Mr.copy(this.origin).addScaledVector(this.direction,n),Mr.distanceToSquared(e))}distanceSqToSegment(e,n,r,i){Tf.copy(e).add(n).multiplyScalar(.5),Ba.copy(n).sub(e).normalize(),Gr.copy(this.origin).sub(Tf);let o=e.distanceTo(n)*.5,s=-this.direction.dot(Ba),a=Gr.dot(this.direction),l=-Gr.dot(Ba),u=Gr.lengthSq(),c=Math.abs(1-s*s),f,h,d,x;if(c>0)if(f=s*l-a,h=s*a-l,x=o*c,f>=0)if(h>=-x)if(h<=x){let p=1/c;f*=p,h*=p,d=f*(f+s*h+2*a)+h*(s*f+h+2*l)+u}else h=o,f=Math.max(0,-(s*h+a)),d=-f*f+h*(h+2*l)+u;else h=-o,f=Math.max(0,-(s*h+a)),d=-f*f+h*(h+2*l)+u;else h<=-x?(f=Math.max(0,-(-s*o+a)),h=f>0?-o:Math.min(Math.max(-o,-l),o),d=-f*f+h*(h+2*l)+u):h<=x?(f=0,h=Math.min(Math.max(-o,-l),o),d=h*(h+2*l)+u):(f=Math.max(0,-(s*o+a)),h=f>0?o:Math.min(Math.max(-o,-l),o),d=-f*f+h*(h+2*l)+u);else h=s>0?-o:o,f=Math.max(0,-(s*h+a)),d=-f*f+h*(h+2*l)+u;return r&&r.copy(this.origin).addScaledVector(this.direction,f),i&&i.copy(Tf).addScaledVector(Ba,h),d}intersectSphere(e,n){Mr.subVectors(e.center,this.origin);let r=Mr.dot(this.direction),i=Mr.dot(Mr)-r*r,o=e.radius*e.radius;if(i>o)return null;let s=Math.sqrt(o-i),a=r-s,l=r+s;return l<0?null:a<0?this.at(l,n):this.at(a,n)}intersectsSphere(e){return e.radius<0?!1:this.distanceSqToPoint(e.center)<=e.radius*e.radius}distanceToPlane(e){let n=e.normal.dot(this.direction);if(n===0)return e.distanceToPoint(this.origin)===0?0:null;let r=-(this.origin.dot(e.normal)+e.constant)/n;return r>=0?r:null}intersectPlane(e,n){let r=this.distanceToPlane(e);return r===null?null:this.at(r,n)}intersectsPlane(e){let n=e.distanceToPoint(this.origin);return n===0||e.normal.dot(this.direction)*n<0}intersectBox(e,n){let r,i,o,s,a,l,u=1/this.direction.x,c=1/this.direction.y,f=1/this.direction.z,h=this.origin;return u>=0?(r=(e.min.x-h.x)*u,i=(e.max.x-h.x)*u):(r=(e.max.x-h.x)*u,i=(e.min.x-h.x)*u),c>=0?(o=(e.min.y-h.y)*c,s=(e.max.y-h.y)*c):(o=(e.max.y-h.y)*c,s=(e.min.y-h.y)*c),r>s||o>i||((o>r||isNaN(r))&&(r=o),(s<i||isNaN(i))&&(i=s),f>=0?(a=(e.min.z-h.z)*f,l=(e.max.z-h.z)*f):(a=(e.max.z-h.z)*f,l=(e.min.z-h.z)*f),r>l||a>i)||((a>r||r!==r)&&(r=a),(l<i||i!==i)&&(i=l),i<0)?null:this.at(r>=0?r:i,n)}intersectsBox(e){return this.intersectBox(e,Mr)!==null}intersectTriangle(e,n,r,i,o){Rf.subVectors(n,e),Ua.subVectors(r,e),Ff.crossVectors(Rf,Ua);let s=this.direction.dot(Ff),a;if(s>0){if(i)return null;a=1}else if(s<0)a=-1,s=-s;else return null;Gr.subVectors(this.origin,e);let l=a*this.direction.dot(Ua.crossVectors(Gr,Ua));if(l<0)return null;let u=a*this.direction.dot(Rf.cross(Gr));if(u<0||l+u>s)return null;let c=-a*Gr.dot(Ff);return c<0?null:this.at(c/s,o)}applyMatrix4(e){return this.origin.applyMatrix4(e),this.direction.transformDirection(e),this}equals(e){return e.origin.equals(this.origin)&&e.direction.equals(this.direction)}clone(){return new this.constructor().copy(this)}},Rt=class t{constructor(e,n,r,i,o,s,a,l,u,c,f,h,d,x,p,g){t.prototype.isMatrix4=!0,this.elements=[1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1],e!==void 0&&this.set(e,n,r,i,o,s,a,l,u,c,f,h,d,x,p,g)}set(e,n,r,i,o,s,a,l,u,c,f,h,d,x,p,g){let m=this.elements;return m[0]=e,m[4]=n,m[8]=r,m[12]=i,m[1]=o,m[5]=s,m[9]=a,m[13]=l,m[2]=u,m[6]=c,m[10]=f,m[14]=h,m[3]=d,m[7]=x,m[11]=p,m[15]=g,this}identity(){return this.set(1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1),this}clone(){return new t().fromArray(this.elements)}copy(e){let n=this.elements,r=e.elements;return n[0]=r[0],n[1]=r[1],n[2]=r[2],n[3]=r[3],n[4]=r[4],n[5]=r[5],n[6]=r[6],n[7]=r[7],n[8]=r[8],n[9]=r[9],n[10]=r[10],n[11]=r[11],n[12]=r[12],n[13]=r[13],n[14]=r[14],n[15]=r[15],this}copyPosition(e){let n=this.elements,r=e.elements;return n[12]=r[12],n[13]=r[13],n[14]=r[14],this}setFromMatrix3(e){let n=e.elements;return this.set(n[0],n[3],n[6],0,n[1],n[4],n[7],0,n[2],n[5],n[8],0,0,0,0,1),this}extractBasis(e,n,r){return e.setFromMatrixColumn(this,0),n.setFromMatrixColumn(this,1),r.setFromMatrixColumn(this,2),this}makeBasis(e,n,r){return this.set(e.x,n.x,r.x,0,e.y,n.y,r.y,0,e.z,n.z,r.z,0,0,0,0,1),this}extractRotation(e){let n=this.elements,r=e.elements,i=1/ho.setFromMatrixColumn(e,0).length(),o=1/ho.setFromMatrixColumn(e,1).length(),s=1/ho.setFromMatrixColumn(e,2).length();return n[0]=r[0]*i,n[1]=r[1]*i,n[2]=r[2]*i,n[3]=0,n[4]=r[4]*o,n[5]=r[5]*o,n[6]=r[6]*o,n[7]=0,n[8]=r[8]*s,n[9]=r[9]*s,n[10]=r[10]*s,n[11]=0,n[12]=0,n[13]=0,n[14]=0,n[15]=1,this}makeRotationFromEuler(e){let n=this.elements,r=e.x,i=e.y,o=e.z,s=Math.cos(r),a=Math.sin(r),l=Math.cos(i),u=Math.sin(i),c=Math.cos(o),f=Math.sin(o);if(e.order==="XYZ"){let h=s*c,d=s*f,x=a*c,p=a*f;n[0]=l*c,n[4]=-l*f,n[8]=u,n[1]=d+x*u,n[5]=h-p*u,n[9]=-a*l,n[2]=p-h*u,n[6]=x+d*u,n[10]=s*l}else if(e.order==="YXZ"){let h=l*c,d=l*f,x=u*c,p=u*f;n[0]=h+p*a,n[4]=x*a-d,n[8]=s*u,n[1]=s*f,n[5]=s*c,n[9]=-a,n[2]=d*a-x,n[6]=p+h*a,n[10]=s*l}else if(e.order==="ZXY"){let h=l*c,d=l*f,x=u*c,p=u*f;n[0]=h-p*a,n[4]=-s*f,n[8]=x+d*a,n[1]=d+x*a,n[5]=s*c,n[9]=p-h*a,n[2]=-s*u,n[6]=a,n[10]=s*l}else if(e.order==="ZYX"){let h=s*c,d=s*f,x=a*c,p=a*f;n[0]=l*c,n[4]=x*u-d,n[8]=h*u+p,n[1]=l*f,n[5]=p*u+h,n[9]=d*u-x,n[2]=-u,n[6]=a*l,n[10]=s*l}else if(e.order==="YZX"){let h=s*l,d=s*u,x=a*l,p=a*u;n[0]=l*c,n[4]=p-h*f,n[8]=x*f+d,n[1]=f,n[5]=s*c,n[9]=-a*c,n[2]=-u*c,n[6]=d*f+x,n[10]=h-p*f}else if(e.order==="XZY"){let h=s*l,d=s*u,x=a*l,p=a*u;n[0]=l*c,n[4]=-f,n[8]=u*c,n[1]=h*f+p,n[5]=s*c,n[9]=d*f-x,n[2]=x*f-d,n[6]=a*c,n[10]=p*f+h}return n[3]=0,n[7]=0,n[11]=0,n[12]=0,n[13]=0,n[14]=0,n[15]=1,this}makeRotationFromQuaternion(e){return this.compose(By,e,Uy)}lookAt(e,n,r){let i=this.elements;return En.subVectors(e,n),En.lengthSq()===0&&(En.z=1),En.normalize(),Wr.crossVectors(r,En),Wr.lengthSq()===0&&(Math.abs(r.z)===1?En.x+=1e-4:En.z+=1e-4,En.normalize(),Wr.crossVectors(r,En)),Wr.normalize(),Oa.crossVectors(En,Wr),i[0]=Wr.x,i[4]=Oa.x,i[8]=En.x,i[1]=Wr.y,i[5]=Oa.y,i[9]=En.y,i[2]=Wr.z,i[6]=Oa.z,i[10]=En.z,this}multiply(e){return this.multiplyMatrices(this,e)}premultiply(e){return this.multiplyMatrices(e,this)}multiplyMatrices(e,n){let r=e.elements,i=n.elements,o=this.elements,s=r[0],a=r[4],l=r[8],u=r[12],c=r[1],f=r[5],h=r[9],d=r[13],x=r[2],p=r[6],g=r[10],m=r[14],b=r[3],v=r[7],_=r[11],M=r[15],y=i[0],E=i[4],D=i[8],S=i[12],w=i[1],C=i[5],F=i[9],O=i[13],U=i[2],z=i[6],B=i[10],J=i[14],H=i[3],ne=i[7],se=i[11],ge=i[15];return o[0]=s*y+a*w+l*U+u*H,o[4]=s*E+a*C+l*z+u*ne,o[8]=s*D+a*F+l*B+u*se,o[12]=s*S+a*O+l*J+u*ge,o[1]=c*y+f*w+h*U+d*H,o[5]=c*E+f*C+h*z+d*ne,o[9]=c*D+f*F+h*B+d*se,o[13]=c*S+f*O+h*J+d*ge,o[2]=x*y+p*w+g*U+m*H,o[6]=x*E+p*C+g*z+m*ne,o[10]=x*D+p*F+g*B+m*se,o[14]=x*S+p*O+g*J+m*ge,o[3]=b*y+v*w+_*U+M*H,o[7]=b*E+v*C+_*z+M*ne,o[11]=b*D+v*F+_*B+M*se,o[15]=b*S+v*O+_*J+M*ge,this}multiplyScalar(e){let n=this.elements;return n[0]*=e,n[4]*=e,n[8]*=e,n[12]*=e,n[1]*=e,n[5]*=e,n[9]*=e,n[13]*=e,n[2]*=e,n[6]*=e,n[10]*=e,n[14]*=e,n[3]*=e,n[7]*=e,n[11]*=e,n[15]*=e,this}determinant(){let e=this.elements,n=e[0],r=e[4],i=e[8],o=e[12],s=e[1],a=e[5],l=e[9],u=e[13],c=e[2],f=e[6],h=e[10],d=e[14],x=e[3],p=e[7],g=e[11],m=e[15];return x*(+o*l*f-i*u*f-o*a*h+r*u*h+i*a*d-r*l*d)+p*(+n*l*d-n*u*h+o*s*h-i*s*d+i*u*c-o*l*c)+g*(+n*u*f-n*a*d-o*s*f+r*s*d+o*a*c-r*u*c)+m*(-i*a*c-n*l*f+n*a*h+i*s*f-r*s*h+r*l*c)}transpose(){let e=this.elements,n;return n=e[1],e[1]=e[4],e[4]=n,n=e[2],e[2]=e[8],e[8]=n,n=e[6],e[6]=e[9],e[9]=n,n=e[3],e[3]=e[12],e[12]=n,n=e[7],e[7]=e[13],e[13]=n,n=e[11],e[11]=e[14],e[14]=n,this}setPosition(e,n,r){let i=this.elements;return e.isVector3?(i[12]=e.x,i[13]=e.y,i[14]=e.z):(i[12]=e,i[13]=n,i[14]=r),this}invert(){let e=this.elements,n=e[0],r=e[1],i=e[2],o=e[3],s=e[4],a=e[5],l=e[6],u=e[7],c=e[8],f=e[9],h=e[10],d=e[11],x=e[12],p=e[13],g=e[14],m=e[15],b=f*g*u-p*h*u+p*l*d-a*g*d-f*l*m+a*h*m,v=x*h*u-c*g*u-x*l*d+s*g*d+c*l*m-s*h*m,_=c*p*u-x*f*u+x*a*d-s*p*d-c*a*m+s*f*m,M=x*f*l-c*p*l-x*a*h+s*p*h+c*a*g-s*f*g,y=n*b+r*v+i*_+o*M;if(y===0)return this.set(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);let E=1/y;return e[0]=b*E,e[1]=(p*h*o-f*g*o-p*i*d+r*g*d+f*i*m-r*h*m)*E,e[2]=(a*g*o-p*l*o+p*i*u-r*g*u-a*i*m+r*l*m)*E,e[3]=(f*l*o-a*h*o-f*i*u+r*h*u+a*i*d-r*l*d)*E,e[4]=v*E,e[5]=(c*g*o-x*h*o+x*i*d-n*g*d-c*i*m+n*h*m)*E,e[6]=(x*l*o-s*g*o-x*i*u+n*g*u+s*i*m-n*l*m)*E,e[7]=(s*h*o-c*l*o+c*i*u-n*h*u-s*i*d+n*l*d)*E,e[8]=_*E,e[9]=(x*f*o-c*p*o-x*r*d+n*p*d+c*r*m-n*f*m)*E,e[10]=(s*p*o-x*a*o+x*r*u-n*p*u-s*r*m+n*a*m)*E,e[11]=(c*a*o-s*f*o-c*r*u+n*f*u+s*r*d-n*a*d)*E,e[12]=M*E,e[13]=(c*p*i-x*f*i+x*r*h-n*p*h-c*r*g+n*f*g)*E,e[14]=(x*a*i-s*p*i-x*r*l+n*p*l+s*r*g-n*a*g)*E,e[15]=(s*f*i-c*a*i+c*r*l-n*f*l-s*r*h+n*a*h)*E,this}scale(e){let n=this.elements,r=e.x,i=e.y,o=e.z;return n[0]*=r,n[4]*=i,n[8]*=o,n[1]*=r,n[5]*=i,n[9]*=o,n[2]*=r,n[6]*=i,n[10]*=o,n[3]*=r,n[7]*=i,n[11]*=o,this}getMaxScaleOnAxis(){let e=this.elements,n=e[0]*e[0]+e[1]*e[1]+e[2]*e[2],r=e[4]*e[4]+e[5]*e[5]+e[6]*e[6],i=e[8]*e[8]+e[9]*e[9]+e[10]*e[10];return Math.sqrt(Math.max(n,r,i))}makeTranslation(e,n,r){return e.isVector3?this.set(1,0,0,e.x,0,1,0,e.y,0,0,1,e.z,0,0,0,1):this.set(1,0,0,e,0,1,0,n,0,0,1,r,0,0,0,1),this}makeRotationX(e){let n=Math.cos(e),r=Math.sin(e);return this.set(1,0,0,0,0,n,-r,0,0,r,n,0,0,0,0,1),this}makeRotationY(e){let n=Math.cos(e),r=Math.sin(e);return this.set(n,0,r,0,0,1,0,0,-r,0,n,0,0,0,0,1),this}makeRotationZ(e){let n=Math.cos(e),r=Math.sin(e);return this.set(n,-r,0,0,r,n,0,0,0,0,1,0,0,0,0,1),this}makeRotationAxis(e,n){let r=Math.cos(n),i=Math.sin(n),o=1-r,s=e.x,a=e.y,l=e.z,u=o*s,c=o*a;return this.set(u*s+r,u*a-i*l,u*l+i*a,0,u*a+i*l,c*a+r,c*l-i*s,0,u*l-i*a,c*l+i*s,o*l*l+r,0,0,0,0,1),this}makeScale(e,n,r){return this.set(e,0,0,0,0,n,0,0,0,0,r,0,0,0,0,1),this}makeShear(e,n,r,i,o,s){return this.set(1,r,o,0,e,1,s,0,n,i,1,0,0,0,0,1),this}compose(e,n,r){let i=this.elements,o=n._x,s=n._y,a=n._z,l=n._w,u=o+o,c=s+s,f=a+a,h=o*u,d=o*c,x=o*f,p=s*c,g=s*f,m=a*f,b=l*u,v=l*c,_=l*f,M=r.x,y=r.y,E=r.z;return i[0]=(1-(p+m))*M,i[1]=(d+_)*M,i[2]=(x-v)*M,i[3]=0,i[4]=(d-_)*y,i[5]=(1-(h+m))*y,i[6]=(g+b)*y,i[7]=0,i[8]=(x+v)*E,i[9]=(g-b)*E,i[10]=(1-(h+p))*E,i[11]=0,i[12]=e.x,i[13]=e.y,i[14]=e.z,i[15]=1,this}decompose(e,n,r){let i=this.elements,o=ho.set(i[0],i[1],i[2]).length(),s=ho.set(i[4],i[5],i[6]).length(),a=ho.set(i[8],i[9],i[10]).length();this.determinant()<0&&(o=-o),e.x=i[12],e.y=i[13],e.z=i[14],Yn.copy(this);let u=1/o,c=1/s,f=1/a;return Yn.elements[0]*=u,Yn.elements[1]*=u,Yn.elements[2]*=u,Yn.elements[4]*=c,Yn.elements[5]*=c,Yn.elements[6]*=c,Yn.elements[8]*=f,Yn.elements[9]*=f,Yn.elements[10]*=f,n.setFromRotationMatrix(Yn),r.x=o,r.y=s,r.z=a,this}makePerspective(e,n,r,i,o,s,a=$n,l=!1){let u=this.elements,c=2*o/(n-e),f=2*o/(r-i),h=(n+e)/(n-e),d=(r+i)/(r-i),x,p;if(l)x=o/(s-o),p=s*o/(s-o);else if(a===$n)x=-(s+o)/(s-o),p=-2*s*o/(s-o);else if(a===Ss)x=-s/(s-o),p=-s*o/(s-o);else throw new Error("THREE.Matrix4.makePerspective(): Invalid coordinate system: "+a);return u[0]=c,u[4]=0,u[8]=h,u[12]=0,u[1]=0,u[5]=f,u[9]=d,u[13]=0,u[2]=0,u[6]=0,u[10]=x,u[14]=p,u[3]=0,u[7]=0,u[11]=-1,u[15]=0,this}makeOrthographic(e,n,r,i,o,s,a=$n,l=!1){let u=this.elements,c=2/(n-e),f=2/(r-i),h=-(n+e)/(n-e),d=-(r+i)/(r-i),x,p;if(l)x=1/(s-o),p=s/(s-o);else if(a===$n)x=-2/(s-o),p=-(s+o)/(s-o);else if(a===Ss)x=-1/(s-o),p=-o/(s-o);else throw new Error("THREE.Matrix4.makeOrthographic(): Invalid coordinate system: "+a);return u[0]=c,u[4]=0,u[8]=0,u[12]=h,u[1]=0,u[5]=f,u[9]=0,u[13]=d,u[2]=0,u[6]=0,u[10]=x,u[14]=p,u[3]=0,u[7]=0,u[11]=0,u[15]=1,this}equals(e){let n=this.elements,r=e.elements;for(let i=0;i<16;i++)if(n[i]!==r[i])return!1;return!0}fromArray(e,n=0){for(let r=0;r<16;r++)this.elements[r]=e[r+n];return this}toArray(e=[],n=0){let r=this.elements;return e[n]=r[0],e[n+1]=r[1],e[n+2]=r[2],e[n+3]=r[3],e[n+4]=r[4],e[n+5]=r[5],e[n+6]=r[6],e[n+7]=r[7],e[n+8]=r[8],e[n+9]=r[9],e[n+10]=r[10],e[n+11]=r[11],e[n+12]=r[12],e[n+13]=r[13],e[n+14]=r[14],e[n+15]=r[15],e}},ho=new k,Yn=new Rt,By=new k(0,0,0),Uy=new k(1,1,1),Wr=new k,Oa=new k,En=new k,tm=new Rt,nm=new kn,Kn=class t{constructor(e=0,n=0,r=0,i=t.DEFAULT_ORDER){this.isEuler=!0,this._x=e,this._y=n,this._z=r,this._order=i}get x(){return this._x}set x(e){this._x=e,this._onChangeCallback()}get y(){return this._y}set y(e){this._y=e,this._onChangeCallback()}get z(){return this._z}set z(e){this._z=e,this._onChangeCallback()}get order(){return this._order}set order(e){this._order=e,this._onChangeCallback()}set(e,n,r,i=this._order){return this._x=e,this._y=n,this._z=r,this._order=i,this._onChangeCallback(),this}clone(){return new this.constructor(this._x,this._y,this._z,this._order)}copy(e){return this._x=e._x,this._y=e._y,this._z=e._z,this._order=e._order,this._onChangeCallback(),this}setFromRotationMatrix(e,n=this._order,r=!0){let i=e.elements,o=i[0],s=i[4],a=i[8],l=i[1],u=i[5],c=i[9],f=i[2],h=i[6],d=i[10];switch(n){case"XYZ":this._y=Math.asin(Qe(a,-1,1)),Math.abs(a)<.9999999?(this._x=Math.atan2(-c,d),this._z=Math.atan2(-s,o)):(this._x=Math.atan2(h,u),this._z=0);break;case"YXZ":this._x=Math.asin(-Qe(c,-1,1)),Math.abs(c)<.9999999?(this._y=Math.atan2(a,d),this._z=Math.atan2(l,u)):(this._y=Math.atan2(-f,o),this._z=0);break;case"ZXY":this._x=Math.asin(Qe(h,-1,1)),Math.abs(h)<.9999999?(this._y=Math.atan2(-f,d),this._z=Math.atan2(-s,u)):(this._y=0,this._z=Math.atan2(l,o));break;case"ZYX":this._y=Math.asin(-Qe(f,-1,1)),Math.abs(f)<.9999999?(this._x=Math.atan2(h,d),this._z=Math.atan2(l,o)):(this._x=0,this._z=Math.atan2(-s,u));break;case"YZX":this._z=Math.asin(Qe(l,-1,1)),Math.abs(l)<.9999999?(this._x=Math.atan2(-c,u),this._y=Math.atan2(-f,o)):(this._x=0,this._y=Math.atan2(a,d));break;case"XZY":this._z=Math.asin(-Qe(s,-1,1)),Math.abs(s)<.9999999?(this._x=Math.atan2(h,u),this._y=Math.atan2(a,o)):(this._x=Math.atan2(-c,d),this._y=0);break;default:console.warn("THREE.Euler: .setFromRotationMatrix() encountered an unknown order: "+n)}return this._order=n,r===!0&&this._onChangeCallback(),this}setFromQuaternion(e,n,r){return tm.makeRotationFromQuaternion(e),this.setFromRotationMatrix(tm,n,r)}setFromVector3(e,n=this._order){return this.set(e.x,e.y,e.z,n)}reorder(e){return nm.setFromEuler(this),this.setFromQuaternion(nm,e)}equals(e){return e._x===this._x&&e._y===this._y&&e._z===this._z&&e._order===this._order}fromArray(e){return this._x=e[0],this._y=e[1],this._z=e[2],e[3]!==void 0&&(this._order=e[3]),this._onChangeCallback(),this}toArray(e=[],n=0){return e[n]=this._x,e[n+1]=this._y,e[n+2]=this._z,e[n+3]=this._order,e}_onChange(e){return this._onChangeCallback=e,this}_onChangeCallback(){}*[Symbol.iterator](){yield this._x,yield this._y,yield this._z,yield this._order}};Kn.DEFAULT_ORDER="XYZ";var Es=class{constructor(){this.mask=1}set(e){this.mask=(1<<e|0)>>>0}enable(e){this.mask|=1<<e|0}enableAll(){this.mask=-1}toggle(e){this.mask^=1<<e|0}disable(e){this.mask&=~(1<<e|0)}disableAll(){this.mask=0}test(e){return(this.mask&e.mask)!==0}isEnabled(e){return(this.mask&(1<<e|0))!==0}},Oy=0,rm=new k,po=new kn,Sr=new Rt,za=new k,ds=new k,zy=new k,ky=new kn,im=new k(1,0,0),om=new k(0,1,0),sm=new k(0,0,1),am={type:"added"},Vy={type:"removed"},mo={type:"childadded",child:null},Pf={type:"childremoved",child:null},Xt=class t extends ur{constructor(){super(),this.isObject3D=!0,Object.defineProperty(this,"id",{value:Oy++}),this.uuid=Oo(),this.name="",this.type="Object3D",this.parent=null,this.children=[],this.up=t.DEFAULT_UP.clone();let e=new k,n=new Kn,r=new kn,i=new k(1,1,1);function o(){r.setFromEuler(n,!1)}function s(){n.setFromQuaternion(r,void 0,!1)}n._onChange(o),r._onChange(s),Object.defineProperties(this,{position:{configurable:!0,enumerable:!0,value:e},rotation:{configurable:!0,enumerable:!0,value:n},quaternion:{configurable:!0,enumerable:!0,value:r},scale:{configurable:!0,enumerable:!0,value:i},modelViewMatrix:{value:new Rt},normalMatrix:{value:new Ke}}),this.matrix=new Rt,this.matrixWorld=new Rt,this.matrixAutoUpdate=t.DEFAULT_MATRIX_AUTO_UPDATE,this.matrixWorldAutoUpdate=t.DEFAULT_MATRIX_WORLD_AUTO_UPDATE,this.matrixWorldNeedsUpdate=!1,this.layers=new Es,this.visible=!0,this.castShadow=!1,this.receiveShadow=!1,this.frustumCulled=!0,this.renderOrder=0,this.animations=[],this.customDepthMaterial=void 0,this.customDistanceMaterial=void 0,this.userData={}}onBeforeShadow(){}onAfterShadow(){}onBeforeRender(){}onAfterRender(){}applyMatrix4(e){this.matrixAutoUpdate&&this.updateMatrix(),this.matrix.premultiply(e),this.matrix.decompose(this.position,this.quaternion,this.scale)}applyQuaternion(e){return this.quaternion.premultiply(e),this}setRotationFromAxisAngle(e,n){this.quaternion.setFromAxisAngle(e,n)}setRotationFromEuler(e){this.quaternion.setFromEuler(e,!0)}setRotationFromMatrix(e){this.quaternion.setFromRotationMatrix(e)}setRotationFromQuaternion(e){this.quaternion.copy(e)}rotateOnAxis(e,n){return po.setFromAxisAngle(e,n),this.quaternion.multiply(po),this}rotateOnWorldAxis(e,n){return po.setFromAxisAngle(e,n),this.quaternion.premultiply(po),this}rotateX(e){return this.rotateOnAxis(im,e)}rotateY(e){return this.rotateOnAxis(om,e)}rotateZ(e){return this.rotateOnAxis(sm,e)}translateOnAxis(e,n){return rm.copy(e).applyQuaternion(this.quaternion),this.position.add(rm.multiplyScalar(n)),this}translateX(e){return this.translateOnAxis(im,e)}translateY(e){return this.translateOnAxis(om,e)}translateZ(e){return this.translateOnAxis(sm,e)}localToWorld(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(this.matrixWorld)}worldToLocal(e){return this.updateWorldMatrix(!0,!1),e.applyMatrix4(Sr.copy(this.matrixWorld).invert())}lookAt(e,n,r){e.isVector3?za.copy(e):za.set(e,n,r);let i=this.parent;this.updateWorldMatrix(!0,!1),ds.setFromMatrixPosition(this.matrixWorld),this.isCamera||this.isLight?Sr.lookAt(ds,za,this.up):Sr.lookAt(za,ds,this.up),this.quaternion.setFromRotationMatrix(Sr),i&&(Sr.extractRotation(i.matrixWorld),po.setFromRotationMatrix(Sr),this.quaternion.premultiply(po.invert()))}add(e){if(arguments.length>1){for(let n=0;n<arguments.length;n++)this.add(arguments[n]);return this}return e===this?(console.error("THREE.Object3D.add: object can't be added as a child of itself.",e),this):(e&&e.isObject3D?(e.removeFromParent(),e.parent=this,this.children.push(e),e.dispatchEvent(am),mo.child=e,this.dispatchEvent(mo),mo.child=null):console.error("THREE.Object3D.add: object not an instance of THREE.Object3D.",e),this)}remove(e){if(arguments.length>1){for(let r=0;r<arguments.length;r++)this.remove(arguments[r]);return this}let n=this.children.indexOf(e);return n!==-1&&(e.parent=null,this.children.splice(n,1),e.dispatchEvent(Vy),Pf.child=e,this.dispatchEvent(Pf),Pf.child=null),this}removeFromParent(){let e=this.parent;return e!==null&&e.remove(this),this}clear(){return this.remove(...this.children)}attach(e){return this.updateWorldMatrix(!0,!1),Sr.copy(this.matrixWorld).invert(),e.parent!==null&&(e.parent.updateWorldMatrix(!0,!1),Sr.multiply(e.parent.matrixWorld)),e.applyMatrix4(Sr),e.removeFromParent(),e.parent=this,this.children.push(e),e.updateWorldMatrix(!1,!0),e.dispatchEvent(am),mo.child=e,this.dispatchEvent(mo),mo.child=null,this}getObjectById(e){return this.getObjectByProperty("id",e)}getObjectByName(e){return this.getObjectByProperty("name",e)}getObjectByProperty(e,n){if(this[e]===n)return this;for(let r=0,i=this.children.length;r<i;r++){let s=this.children[r].getObjectByProperty(e,n);if(s!==void 0)return s}}getObjectsByProperty(e,n,r=[]){this[e]===n&&r.push(this);let i=this.children;for(let o=0,s=i.length;o<s;o++)i[o].getObjectsByProperty(e,n,r);return r}getWorldPosition(e){return this.updateWorldMatrix(!0,!1),e.setFromMatrixPosition(this.matrixWorld)}getWorldQuaternion(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(ds,e,zy),e}getWorldScale(e){return this.updateWorldMatrix(!0,!1),this.matrixWorld.decompose(ds,ky,e),e}getWorldDirection(e){this.updateWorldMatrix(!0,!1);let n=this.matrixWorld.elements;return e.set(n[8],n[9],n[10]).normalize()}raycast(){}traverse(e){e(this);let n=this.children;for(let r=0,i=n.length;r<i;r++)n[r].traverse(e)}traverseVisible(e){if(this.visible===!1)return;e(this);let n=this.children;for(let r=0,i=n.length;r<i;r++)n[r].traverseVisible(e)}traverseAncestors(e){let n=this.parent;n!==null&&(e(n),n.traverseAncestors(e))}updateMatrix(){this.matrix.compose(this.position,this.quaternion,this.scale),this.matrixWorldNeedsUpdate=!0}updateMatrixWorld(e){this.matrixAutoUpdate&&this.updateMatrix(),(this.matrixWorldNeedsUpdate||e)&&(this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),this.matrixWorldNeedsUpdate=!1,e=!0);let n=this.children;for(let r=0,i=n.length;r<i;r++)n[r].updateMatrixWorld(e)}updateWorldMatrix(e,n){let r=this.parent;if(e===!0&&r!==null&&r.updateWorldMatrix(!0,!1),this.matrixAutoUpdate&&this.updateMatrix(),this.matrixWorldAutoUpdate===!0&&(this.parent===null?this.matrixWorld.copy(this.matrix):this.matrixWorld.multiplyMatrices(this.parent.matrixWorld,this.matrix)),n===!0){let i=this.children;for(let o=0,s=i.length;o<s;o++)i[o].updateWorldMatrix(!1,!0)}}toJSON(e){let n=e===void 0||typeof e=="string",r={};n&&(e={geometries:{},materials:{},textures:{},images:{},shapes:{},skeletons:{},animations:{},nodes:{}},r.metadata={version:4.7,type:"Object",generator:"Object3D.toJSON"});let i={};i.uuid=this.uuid,i.type=this.type,this.name!==""&&(i.name=this.name),this.castShadow===!0&&(i.castShadow=!0),this.receiveShadow===!0&&(i.receiveShadow=!0),this.visible===!1&&(i.visible=!1),this.frustumCulled===!1&&(i.frustumCulled=!1),this.renderOrder!==0&&(i.renderOrder=this.renderOrder),Object.keys(this.userData).length>0&&(i.userData=this.userData),i.layers=this.layers.mask,i.matrix=this.matrix.toArray(),i.up=this.up.toArray(),this.matrixAutoUpdate===!1&&(i.matrixAutoUpdate=!1),this.isInstancedMesh&&(i.type="InstancedMesh",i.count=this.count,i.instanceMatrix=this.instanceMatrix.toJSON(),this.instanceColor!==null&&(i.instanceColor=this.instanceColor.toJSON())),this.isBatchedMesh&&(i.type="BatchedMesh",i.perObjectFrustumCulled=this.perObjectFrustumCulled,i.sortObjects=this.sortObjects,i.drawRanges=this._drawRanges,i.reservedRanges=this._reservedRanges,i.geometryInfo=this._geometryInfo.map(a=>({...a,boundingBox:a.boundingBox?a.boundingBox.toJSON():void 0,boundingSphere:a.boundingSphere?a.boundingSphere.toJSON():void 0})),i.instanceInfo=this._instanceInfo.map(a=>({...a})),i.availableInstanceIds=this._availableInstanceIds.slice(),i.availableGeometryIds=this._availableGeometryIds.slice(),i.nextIndexStart=this._nextIndexStart,i.nextVertexStart=this._nextVertexStart,i.geometryCount=this._geometryCount,i.maxInstanceCount=this._maxInstanceCount,i.maxVertexCount=this._maxVertexCount,i.maxIndexCount=this._maxIndexCount,i.geometryInitialized=this._geometryInitialized,i.matricesTexture=this._matricesTexture.toJSON(e),i.indirectTexture=this._indirectTexture.toJSON(e),this._colorsTexture!==null&&(i.colorsTexture=this._colorsTexture.toJSON(e)),this.boundingSphere!==null&&(i.boundingSphere=this.boundingSphere.toJSON()),this.boundingBox!==null&&(i.boundingBox=this.boundingBox.toJSON()));function o(a,l){return a[l.uuid]===void 0&&(a[l.uuid]=l.toJSON(e)),l.uuid}if(this.isScene)this.background&&(this.background.isColor?i.background=this.background.toJSON():this.background.isTexture&&(i.background=this.background.toJSON(e).uuid)),this.environment&&this.environment.isTexture&&this.environment.isRenderTargetTexture!==!0&&(i.environment=this.environment.toJSON(e).uuid);else if(this.isMesh||this.isLine||this.isPoints){i.geometry=o(e.geometries,this.geometry);let a=this.geometry.parameters;if(a!==void 0&&a.shapes!==void 0){let l=a.shapes;if(Array.isArray(l))for(let u=0,c=l.length;u<c;u++){let f=l[u];o(e.shapes,f)}else o(e.shapes,l)}}if(this.isSkinnedMesh&&(i.bindMode=this.bindMode,i.bindMatrix=this.bindMatrix.toArray(),this.skeleton!==void 0&&(o(e.skeletons,this.skeleton),i.skeleton=this.skeleton.uuid)),this.material!==void 0)if(Array.isArray(this.material)){let a=[];for(let l=0,u=this.material.length;l<u;l++)a.push(o(e.materials,this.material[l]));i.material=a}else i.material=o(e.materials,this.material);if(this.children.length>0){i.children=[];for(let a=0;a<this.children.length;a++)i.children.push(this.children[a].toJSON(e).object)}if(this.animations.length>0){i.animations=[];for(let a=0;a<this.animations.length;a++){let l=this.animations[a];i.animations.push(o(e.animations,l))}}if(n){let a=s(e.geometries),l=s(e.materials),u=s(e.textures),c=s(e.images),f=s(e.shapes),h=s(e.skeletons),d=s(e.animations),x=s(e.nodes);a.length>0&&(r.geometries=a),l.length>0&&(r.materials=l),u.length>0&&(r.textures=u),c.length>0&&(r.images=c),f.length>0&&(r.shapes=f),h.length>0&&(r.skeletons=h),d.length>0&&(r.animations=d),x.length>0&&(r.nodes=x)}return r.object=i,r;function s(a){let l=[];for(let u in a){let c=a[u];delete c.metadata,l.push(c)}return l}}clone(e){return new this.constructor().copy(this,e)}copy(e,n=!0){if(this.name=e.name,this.up.copy(e.up),this.position.copy(e.position),this.rotation.order=e.rotation.order,this.quaternion.copy(e.quaternion),this.scale.copy(e.scale),this.matrix.copy(e.matrix),this.matrixWorld.copy(e.matrixWorld),this.matrixAutoUpdate=e.matrixAutoUpdate,this.matrixWorldAutoUpdate=e.matrixWorldAutoUpdate,this.matrixWorldNeedsUpdate=e.matrixWorldNeedsUpdate,this.layers.mask=e.layers.mask,this.visible=e.visible,this.castShadow=e.castShadow,this.receiveShadow=e.receiveShadow,this.frustumCulled=e.frustumCulled,this.renderOrder=e.renderOrder,this.animations=e.animations.slice(),this.userData=JSON.parse(JSON.stringify(e.userData)),n===!0)for(let r=0;r<e.children.length;r++){let i=e.children[r];this.add(i.clone())}return this}};Xt.DEFAULT_UP=new k(0,1,0);Xt.DEFAULT_MATRIX_AUTO_UPDATE=!0;Xt.DEFAULT_MATRIX_WORLD_AUTO_UPDATE=!0;var Zn=new k,wr=new k,If=new k,br=new k,go=new k,xo=new k,um=new k,Nf=new k,Lf=new k,Bf=new k,Uf=new Ft,Of=new Ft,zf=new Ft,Yr=class t{constructor(e=new k,n=new k,r=new k){this.a=e,this.b=n,this.c=r}static getNormal(e,n,r,i){i.subVectors(r,n),Zn.subVectors(e,n),i.cross(Zn);let o=i.lengthSq();return o>0?i.multiplyScalar(1/Math.sqrt(o)):i.set(0,0,0)}static getBarycoord(e,n,r,i,o){Zn.subVectors(i,n),wr.subVectors(r,n),If.subVectors(e,n);let s=Zn.dot(Zn),a=Zn.dot(wr),l=Zn.dot(If),u=wr.dot(wr),c=wr.dot(If),f=s*u-a*a;if(f===0)return o.set(0,0,0),null;let h=1/f,d=(u*l-a*c)*h,x=(s*c-a*l)*h;return o.set(1-d-x,x,d)}static containsPoint(e,n,r,i){return this.getBarycoord(e,n,r,i,br)===null?!1:br.x>=0&&br.y>=0&&br.x+br.y<=1}static getInterpolation(e,n,r,i,o,s,a,l){return this.getBarycoord(e,n,r,i,br)===null?(l.x=0,l.y=0,"z"in l&&(l.z=0),"w"in l&&(l.w=0),null):(l.setScalar(0),l.addScaledVector(o,br.x),l.addScaledVector(s,br.y),l.addScaledVector(a,br.z),l)}static getInterpolatedAttribute(e,n,r,i,o,s){return Uf.setScalar(0),Of.setScalar(0),zf.setScalar(0),Uf.fromBufferAttribute(e,n),Of.fromBufferAttribute(e,r),zf.fromBufferAttribute(e,i),s.setScalar(0),s.addScaledVector(Uf,o.x),s.addScaledVector(Of,o.y),s.addScaledVector(zf,o.z),s}static isFrontFacing(e,n,r,i){return Zn.subVectors(r,n),wr.subVectors(e,n),Zn.cross(wr).dot(i)<0}set(e,n,r){return this.a.copy(e),this.b.copy(n),this.c.copy(r),this}setFromPointsAndIndices(e,n,r,i){return this.a.copy(e[n]),this.b.copy(e[r]),this.c.copy(e[i]),this}setFromAttributeAndIndices(e,n,r,i){return this.a.fromBufferAttribute(e,n),this.b.fromBufferAttribute(e,r),this.c.fromBufferAttribute(e,i),this}clone(){return new this.constructor().copy(this)}copy(e){return this.a.copy(e.a),this.b.copy(e.b),this.c.copy(e.c),this}getArea(){return Zn.subVectors(this.c,this.b),wr.subVectors(this.a,this.b),Zn.cross(wr).length()*.5}getMidpoint(e){return e.addVectors(this.a,this.b).add(this.c).multiplyScalar(1/3)}getNormal(e){return t.getNormal(this.a,this.b,this.c,e)}getPlane(e){return e.setFromCoplanarPoints(this.a,this.b,this.c)}getBarycoord(e,n){return t.getBarycoord(e,this.a,this.b,this.c,n)}getInterpolation(e,n,r,i,o){return t.getInterpolation(e,this.a,this.b,this.c,n,r,i,o)}containsPoint(e){return t.containsPoint(e,this.a,this.b,this.c)}isFrontFacing(e){return t.isFrontFacing(this.a,this.b,this.c,e)}intersectsBox(e){return e.intersectsTriangle(this)}closestPointToPoint(e,n){let r=this.a,i=this.b,o=this.c,s,a;go.subVectors(i,r),xo.subVectors(o,r),Nf.subVectors(e,r);let l=go.dot(Nf),u=xo.dot(Nf);if(l<=0&&u<=0)return n.copy(r);Lf.subVectors(e,i);let c=go.dot(Lf),f=xo.dot(Lf);if(c>=0&&f<=c)return n.copy(i);let h=l*f-c*u;if(h<=0&&l>=0&&c<=0)return s=l/(l-c),n.copy(r).addScaledVector(go,s);Bf.subVectors(e,o);let d=go.dot(Bf),x=xo.dot(Bf);if(x>=0&&d<=x)return n.copy(o);let p=d*u-l*x;if(p<=0&&u>=0&&x<=0)return a=u/(u-x),n.copy(r).addScaledVector(xo,a);let g=c*x-d*f;if(g<=0&&f-c>=0&&d-x>=0)return um.subVectors(o,i),a=(f-c)/(f-c+(d-x)),n.copy(i).addScaledVector(um,a);let m=1/(g+p+h);return s=p*m,a=h*m,n.copy(r).addScaledVector(go,s).addScaledVector(xo,a)}equals(e){return e.a.equals(this.a)&&e.b.equals(this.b)&&e.c.equals(this.c)}},lg={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074},qr={h:0,s:0,l:0},ka={h:0,s:0,l:0};function kf(t,e,n){return n<0&&(n+=1),n>1&&(n-=1),n<1/6?t+(e-t)*6*n:n<1/2?e:n<2/3?t+(e-t)*6*(2/3-n):t}var it=class{constructor(e,n,r){return this.isColor=!0,this.r=1,this.g=1,this.b=1,this.set(e,n,r)}set(e,n,r){if(n===void 0&&r===void 0){let i=e;i&&i.isColor?this.copy(i):typeof i=="number"?this.setHex(i):typeof i=="string"&&this.setStyle(i)}else this.setRGB(e,n,r);return this}setScalar(e){return this.r=e,this.g=e,this.b=e,this}setHex(e,n=An){return e=Math.floor(e),this.r=(e>>16&255)/255,this.g=(e>>8&255)/255,this.b=(e&255)/255,ct.colorSpaceToWorking(this,n),this}setRGB(e,n,r,i=ct.workingColorSpace){return this.r=e,this.g=n,this.b=r,ct.colorSpaceToWorking(this,i),this}setHSL(e,n,r,i=ct.workingColorSpace){if(e=Sh(e,1),n=Qe(n,0,1),r=Qe(r,0,1),n===0)this.r=this.g=this.b=r;else{let o=r<=.5?r*(1+n):r+n-r*n,s=2*r-o;this.r=kf(s,o,e+1/3),this.g=kf(s,o,e),this.b=kf(s,o,e-1/3)}return ct.colorSpaceToWorking(this,i),this}setStyle(e,n=An){function r(o){o!==void 0&&parseFloat(o)<1&&console.warn("THREE.Color: Alpha component of "+e+" will be ignored.")}let i;if(i=/^(\w+)\(([^\)]*)\)/.exec(e)){let o,s=i[1],a=i[2];switch(s){case"rgb":case"rgba":if(o=/^\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(a))return r(o[4]),this.setRGB(Math.min(255,parseInt(o[1],10))/255,Math.min(255,parseInt(o[2],10))/255,Math.min(255,parseInt(o[3],10))/255,n);if(o=/^\s*(\d+)\%\s*,\s*(\d+)\%\s*,\s*(\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(a))return r(o[4]),this.setRGB(Math.min(100,parseInt(o[1],10))/100,Math.min(100,parseInt(o[2],10))/100,Math.min(100,parseInt(o[3],10))/100,n);break;case"hsl":case"hsla":if(o=/^\s*(\d*\.?\d+)\s*,\s*(\d*\.?\d+)\%\s*,\s*(\d*\.?\d+)\%\s*(?:,\s*(\d*\.?\d+)\s*)?$/.exec(a))return r(o[4]),this.setHSL(parseFloat(o[1])/360,parseFloat(o[2])/100,parseFloat(o[3])/100,n);break;default:console.warn("THREE.Color: Unknown color model "+e)}}else if(i=/^\#([A-Fa-f\d]+)$/.exec(e)){let o=i[1],s=o.length;if(s===3)return this.setRGB(parseInt(o.charAt(0),16)/15,parseInt(o.charAt(1),16)/15,parseInt(o.charAt(2),16)/15,n);if(s===6)return this.setHex(parseInt(o,16),n);console.warn("THREE.Color: Invalid hex color "+e)}else if(e&&e.length>0)return this.setColorName(e,n);return this}setColorName(e,n=An){let r=lg[e.toLowerCase()];return r!==void 0?this.setHex(r,n):console.warn("THREE.Color: Unknown color "+e),this}clone(){return new this.constructor(this.r,this.g,this.b)}copy(e){return this.r=e.r,this.g=e.g,this.b=e.b,this}copySRGBToLinear(e){return this.r=Dr(e.r),this.g=Dr(e.g),this.b=Dr(e.b),this}copyLinearToSRGB(e){return this.r=So(e.r),this.g=So(e.g),this.b=So(e.b),this}convertSRGBToLinear(){return this.copySRGBToLinear(this),this}convertLinearToSRGB(){return this.copyLinearToSRGB(this),this}getHex(e=An){return ct.workingToColorSpace(en.copy(this),e),Math.round(Qe(en.r*255,0,255))*65536+Math.round(Qe(en.g*255,0,255))*256+Math.round(Qe(en.b*255,0,255))}getHexString(e=An){return("000000"+this.getHex(e).toString(16)).slice(-6)}getHSL(e,n=ct.workingColorSpace){ct.workingToColorSpace(en.copy(this),n);let r=en.r,i=en.g,o=en.b,s=Math.max(r,i,o),a=Math.min(r,i,o),l,u,c=(a+s)/2;if(a===s)l=0,u=0;else{let f=s-a;switch(u=c<=.5?f/(s+a):f/(2-s-a),s){case r:l=(i-o)/f+(i<o?6:0);break;case i:l=(o-r)/f+2;break;case o:l=(r-i)/f+4;break}l/=6}return e.h=l,e.s=u,e.l=c,e}getRGB(e,n=ct.workingColorSpace){return ct.workingToColorSpace(en.copy(this),n),e.r=en.r,e.g=en.g,e.b=en.b,e}getStyle(e=An){ct.workingToColorSpace(en.copy(this),e);let n=en.r,r=en.g,i=en.b;return e!==An?`color(${e} ${n.toFixed(3)} ${r.toFixed(3)} ${i.toFixed(3)})`:`rgb(${Math.round(n*255)},${Math.round(r*255)},${Math.round(i*255)})`}offsetHSL(e,n,r){return this.getHSL(qr),this.setHSL(qr.h+e,qr.s+n,qr.l+r)}add(e){return this.r+=e.r,this.g+=e.g,this.b+=e.b,this}addColors(e,n){return this.r=e.r+n.r,this.g=e.g+n.g,this.b=e.b+n.b,this}addScalar(e){return this.r+=e,this.g+=e,this.b+=e,this}sub(e){return this.r=Math.max(0,this.r-e.r),this.g=Math.max(0,this.g-e.g),this.b=Math.max(0,this.b-e.b),this}multiply(e){return this.r*=e.r,this.g*=e.g,this.b*=e.b,this}multiplyScalar(e){return this.r*=e,this.g*=e,this.b*=e,this}lerp(e,n){return this.r+=(e.r-this.r)*n,this.g+=(e.g-this.g)*n,this.b+=(e.b-this.b)*n,this}lerpColors(e,n,r){return this.r=e.r+(n.r-e.r)*r,this.g=e.g+(n.g-e.g)*r,this.b=e.b+(n.b-e.b)*r,this}lerpHSL(e,n){this.getHSL(qr),e.getHSL(ka);let r=xs(qr.h,ka.h,n),i=xs(qr.s,ka.s,n),o=xs(qr.l,ka.l,n);return this.setHSL(r,i,o),this}setFromVector3(e){return this.r=e.x,this.g=e.y,this.b=e.z,this}applyMatrix3(e){let n=this.r,r=this.g,i=this.b,o=e.elements;return this.r=o[0]*n+o[3]*r+o[6]*i,this.g=o[1]*n+o[4]*r+o[7]*i,this.b=o[2]*n+o[5]*r+o[8]*i,this}equals(e){return e.r===this.r&&e.g===this.g&&e.b===this.b}fromArray(e,n=0){return this.r=e[n],this.g=e[n+1],this.b=e[n+2],this}toArray(e=[],n=0){return e[n]=this.r,e[n+1]=this.g,e[n+2]=this.b,e}fromBufferAttribute(e,n){return this.r=e.getX(n),this.g=e.getY(n),this.b=e.getZ(n),this}toJSON(){return this.getHex()}*[Symbol.iterator](){yield this.r,yield this.g,yield this.b}},en=new it;it.NAMES=lg;var Hy=0,Cr=class extends ur{constructor(){super(),this.isMaterial=!0,Object.defineProperty(this,"id",{value:Hy++}),this.uuid=Oo(),this.name="",this.type="Material",this.blending=Ei,this.side=Ar,this.vertexColors=!1,this.opacity=1,this.transparent=!1,this.alphaHash=!1,this.blendSrc=nu,this.blendDst=ru,this.blendEquation=$r,this.blendSrcAlpha=null,this.blendDstAlpha=null,this.blendEquationAlpha=null,this.blendColor=new it(0,0,0),this.blendAlpha=0,this.depthFunc=Di,this.depthTest=!0,this.depthWrite=!0,this.stencilWriteMask=255,this.stencilFunc=jf,this.stencilRef=0,this.stencilFuncMask=255,this.stencilFail=bi,this.stencilZFail=bi,this.stencilZPass=bi,this.stencilWrite=!1,this.clippingPlanes=null,this.clipIntersection=!1,this.clipShadows=!1,this.shadowSide=null,this.colorWrite=!0,this.precision=null,this.polygonOffset=!1,this.polygonOffsetFactor=0,this.polygonOffsetUnits=0,this.dithering=!1,this.alphaToCoverage=!1,this.premultipliedAlpha=!1,this.forceSinglePass=!1,this.allowOverride=!0,this.visible=!0,this.toneMapped=!0,this.userData={},this.version=0,this._alphaTest=0}get alphaTest(){return this._alphaTest}set alphaTest(e){this._alphaTest>0!=e>0&&this.version++,this._alphaTest=e}onBeforeRender(){}onBeforeCompile(){}customProgramCacheKey(){return this.onBeforeCompile.toString()}setValues(e){if(e!==void 0)for(let n in e){let r=e[n];if(r===void 0){console.warn(`THREE.Material: parameter '${n}' has value of undefined.`);continue}let i=this[n];if(i===void 0){console.warn(`THREE.Material: '${n}' is not a property of THREE.${this.type}.`);continue}i&&i.isColor?i.set(r):i&&i.isVector3&&r&&r.isVector3?i.copy(r):this[n]=r}}toJSON(e){let n=e===void 0||typeof e=="string";n&&(e={textures:{},images:{}});let r={metadata:{version:4.7,type:"Material",generator:"Material.toJSON"}};r.uuid=this.uuid,r.type=this.type,this.name!==""&&(r.name=this.name),this.color&&this.color.isColor&&(r.color=this.color.getHex()),this.roughness!==void 0&&(r.roughness=this.roughness),this.metalness!==void 0&&(r.metalness=this.metalness),this.sheen!==void 0&&(r.sheen=this.sheen),this.sheenColor&&this.sheenColor.isColor&&(r.sheenColor=this.sheenColor.getHex()),this.sheenRoughness!==void 0&&(r.sheenRoughness=this.sheenRoughness),this.emissive&&this.emissive.isColor&&(r.emissive=this.emissive.getHex()),this.emissiveIntensity!==void 0&&this.emissiveIntensity!==1&&(r.emissiveIntensity=this.emissiveIntensity),this.specular&&this.specular.isColor&&(r.specular=this.specular.getHex()),this.specularIntensity!==void 0&&(r.specularIntensity=this.specularIntensity),this.specularColor&&this.specularColor.isColor&&(r.specularColor=this.specularColor.getHex()),this.shininess!==void 0&&(r.shininess=this.shininess),this.clearcoat!==void 0&&(r.clearcoat=this.clearcoat),this.clearcoatRoughness!==void 0&&(r.clearcoatRoughness=this.clearcoatRoughness),this.clearcoatMap&&this.clearcoatMap.isTexture&&(r.clearcoatMap=this.clearcoatMap.toJSON(e).uuid),this.clearcoatRoughnessMap&&this.clearcoatRoughnessMap.isTexture&&(r.clearcoatRoughnessMap=this.clearcoatRoughnessMap.toJSON(e).uuid),this.clearcoatNormalMap&&this.clearcoatNormalMap.isTexture&&(r.clearcoatNormalMap=this.clearcoatNormalMap.toJSON(e).uuid,r.clearcoatNormalScale=this.clearcoatNormalScale.toArray()),this.sheenColorMap&&this.sheenColorMap.isTexture&&(r.sheenColorMap=this.sheenColorMap.toJSON(e).uuid),this.sheenRoughnessMap&&this.sheenRoughnessMap.isTexture&&(r.sheenRoughnessMap=this.sheenRoughnessMap.toJSON(e).uuid),this.dispersion!==void 0&&(r.dispersion=this.dispersion),this.iridescence!==void 0&&(r.iridescence=this.iridescence),this.iridescenceIOR!==void 0&&(r.iridescenceIOR=this.iridescenceIOR),this.iridescenceThicknessRange!==void 0&&(r.iridescenceThicknessRange=this.iridescenceThicknessRange),this.iridescenceMap&&this.iridescenceMap.isTexture&&(r.iridescenceMap=this.iridescenceMap.toJSON(e).uuid),this.iridescenceThicknessMap&&this.iridescenceThicknessMap.isTexture&&(r.iridescenceThicknessMap=this.iridescenceThicknessMap.toJSON(e).uuid),this.anisotropy!==void 0&&(r.anisotropy=this.anisotropy),this.anisotropyRotation!==void 0&&(r.anisotropyRotation=this.anisotropyRotation),this.anisotropyMap&&this.anisotropyMap.isTexture&&(r.anisotropyMap=this.anisotropyMap.toJSON(e).uuid),this.map&&this.map.isTexture&&(r.map=this.map.toJSON(e).uuid),this.matcap&&this.matcap.isTexture&&(r.matcap=this.matcap.toJSON(e).uuid),this.alphaMap&&this.alphaMap.isTexture&&(r.alphaMap=this.alphaMap.toJSON(e).uuid),this.lightMap&&this.lightMap.isTexture&&(r.lightMap=this.lightMap.toJSON(e).uuid,r.lightMapIntensity=this.lightMapIntensity),this.aoMap&&this.aoMap.isTexture&&(r.aoMap=this.aoMap.toJSON(e).uuid,r.aoMapIntensity=this.aoMapIntensity),this.bumpMap&&this.bumpMap.isTexture&&(r.bumpMap=this.bumpMap.toJSON(e).uuid,r.bumpScale=this.bumpScale),this.normalMap&&this.normalMap.isTexture&&(r.normalMap=this.normalMap.toJSON(e).uuid,r.normalMapType=this.normalMapType,r.normalScale=this.normalScale.toArray()),this.displacementMap&&this.displacementMap.isTexture&&(r.displacementMap=this.displacementMap.toJSON(e).uuid,r.displacementScale=this.displacementScale,r.displacementBias=this.displacementBias),this.roughnessMap&&this.roughnessMap.isTexture&&(r.roughnessMap=this.roughnessMap.toJSON(e).uuid),this.metalnessMap&&this.metalnessMap.isTexture&&(r.metalnessMap=this.metalnessMap.toJSON(e).uuid),this.emissiveMap&&this.emissiveMap.isTexture&&(r.emissiveMap=this.emissiveMap.toJSON(e).uuid),this.specularMap&&this.specularMap.isTexture&&(r.specularMap=this.specularMap.toJSON(e).uuid),this.specularIntensityMap&&this.specularIntensityMap.isTexture&&(r.specularIntensityMap=this.specularIntensityMap.toJSON(e).uuid),this.specularColorMap&&this.specularColorMap.isTexture&&(r.specularColorMap=this.specularColorMap.toJSON(e).uuid),this.envMap&&this.envMap.isTexture&&(r.envMap=this.envMap.toJSON(e).uuid,this.combine!==void 0&&(r.combine=this.combine)),this.envMapRotation!==void 0&&(r.envMapRotation=this.envMapRotation.toArray()),this.envMapIntensity!==void 0&&(r.envMapIntensity=this.envMapIntensity),this.reflectivity!==void 0&&(r.reflectivity=this.reflectivity),this.refractionRatio!==void 0&&(r.refractionRatio=this.refractionRatio),this.gradientMap&&this.gradientMap.isTexture&&(r.gradientMap=this.gradientMap.toJSON(e).uuid),this.transmission!==void 0&&(r.transmission=this.transmission),this.transmissionMap&&this.transmissionMap.isTexture&&(r.transmissionMap=this.transmissionMap.toJSON(e).uuid),this.thickness!==void 0&&(r.thickness=this.thickness),this.thicknessMap&&this.thicknessMap.isTexture&&(r.thicknessMap=this.thicknessMap.toJSON(e).uuid),this.attenuationDistance!==void 0&&this.attenuationDistance!==1/0&&(r.attenuationDistance=this.attenuationDistance),this.attenuationColor!==void 0&&(r.attenuationColor=this.attenuationColor.getHex()),this.size!==void 0&&(r.size=this.size),this.shadowSide!==null&&(r.shadowSide=this.shadowSide),this.sizeAttenuation!==void 0&&(r.sizeAttenuation=this.sizeAttenuation),this.blending!==Ei&&(r.blending=this.blending),this.side!==Ar&&(r.side=this.side),this.vertexColors===!0&&(r.vertexColors=!0),this.opacity<1&&(r.opacity=this.opacity),this.transparent===!0&&(r.transparent=!0),this.blendSrc!==nu&&(r.blendSrc=this.blendSrc),this.blendDst!==ru&&(r.blendDst=this.blendDst),this.blendEquation!==$r&&(r.blendEquation=this.blendEquation),this.blendSrcAlpha!==null&&(r.blendSrcAlpha=this.blendSrcAlpha),this.blendDstAlpha!==null&&(r.blendDstAlpha=this.blendDstAlpha),this.blendEquationAlpha!==null&&(r.blendEquationAlpha=this.blendEquationAlpha),this.blendColor&&this.blendColor.isColor&&(r.blendColor=this.blendColor.getHex()),this.blendAlpha!==0&&(r.blendAlpha=this.blendAlpha),this.depthFunc!==Di&&(r.depthFunc=this.depthFunc),this.depthTest===!1&&(r.depthTest=this.depthTest),this.depthWrite===!1&&(r.depthWrite=this.depthWrite),this.colorWrite===!1&&(r.colorWrite=this.colorWrite),this.stencilWriteMask!==255&&(r.stencilWriteMask=this.stencilWriteMask),this.stencilFunc!==jf&&(r.stencilFunc=this.stencilFunc),this.stencilRef!==0&&(r.stencilRef=this.stencilRef),this.stencilFuncMask!==255&&(r.stencilFuncMask=this.stencilFuncMask),this.stencilFail!==bi&&(r.stencilFail=this.stencilFail),this.stencilZFail!==bi&&(r.stencilZFail=this.stencilZFail),this.stencilZPass!==bi&&(r.stencilZPass=this.stencilZPass),this.stencilWrite===!0&&(r.stencilWrite=this.stencilWrite),this.rotation!==void 0&&this.rotation!==0&&(r.rotation=this.rotation),this.polygonOffset===!0&&(r.polygonOffset=!0),this.polygonOffsetFactor!==0&&(r.polygonOffsetFactor=this.polygonOffsetFactor),this.polygonOffsetUnits!==0&&(r.polygonOffsetUnits=this.polygonOffsetUnits),this.linewidth!==void 0&&this.linewidth!==1&&(r.linewidth=this.linewidth),this.dashSize!==void 0&&(r.dashSize=this.dashSize),this.gapSize!==void 0&&(r.gapSize=this.gapSize),this.scale!==void 0&&(r.scale=this.scale),this.dithering===!0&&(r.dithering=!0),this.alphaTest>0&&(r.alphaTest=this.alphaTest),this.alphaHash===!0&&(r.alphaHash=!0),this.alphaToCoverage===!0&&(r.alphaToCoverage=!0),this.premultipliedAlpha===!0&&(r.premultipliedAlpha=!0),this.forceSinglePass===!0&&(r.forceSinglePass=!0),this.wireframe===!0&&(r.wireframe=!0),this.wireframeLinewidth>1&&(r.wireframeLinewidth=this.wireframeLinewidth),this.wireframeLinecap!=="round"&&(r.wireframeLinecap=this.wireframeLinecap),this.wireframeLinejoin!=="round"&&(r.wireframeLinejoin=this.wireframeLinejoin),this.flatShading===!0&&(r.flatShading=!0),this.visible===!1&&(r.visible=!1),this.toneMapped===!1&&(r.toneMapped=!1),this.fog===!1&&(r.fog=!1),Object.keys(this.userData).length>0&&(r.userData=this.userData);function i(o){let s=[];for(let a in o){let l=o[a];delete l.metadata,s.push(l)}return s}if(n){let o=i(e.textures),s=i(e.images);o.length>0&&(r.textures=o),s.length>0&&(r.images=s)}return r}clone(){return new this.constructor().copy(this)}copy(e){this.name=e.name,this.blending=e.blending,this.side=e.side,this.vertexColors=e.vertexColors,this.opacity=e.opacity,this.transparent=e.transparent,this.blendSrc=e.blendSrc,this.blendDst=e.blendDst,this.blendEquation=e.blendEquation,this.blendSrcAlpha=e.blendSrcAlpha,this.blendDstAlpha=e.blendDstAlpha,this.blendEquationAlpha=e.blendEquationAlpha,this.blendColor.copy(e.blendColor),this.blendAlpha=e.blendAlpha,this.depthFunc=e.depthFunc,this.depthTest=e.depthTest,this.depthWrite=e.depthWrite,this.stencilWriteMask=e.stencilWriteMask,this.stencilFunc=e.stencilFunc,this.stencilRef=e.stencilRef,this.stencilFuncMask=e.stencilFuncMask,this.stencilFail=e.stencilFail,this.stencilZFail=e.stencilZFail,this.stencilZPass=e.stencilZPass,this.stencilWrite=e.stencilWrite;let n=e.clippingPlanes,r=null;if(n!==null){let i=n.length;r=new Array(i);for(let o=0;o!==i;++o)r[o]=n[o].clone()}return this.clippingPlanes=r,this.clipIntersection=e.clipIntersection,this.clipShadows=e.clipShadows,this.shadowSide=e.shadowSide,this.colorWrite=e.colorWrite,this.precision=e.precision,this.polygonOffset=e.polygonOffset,this.polygonOffsetFactor=e.polygonOffsetFactor,this.polygonOffsetUnits=e.polygonOffsetUnits,this.dithering=e.dithering,this.alphaTest=e.alphaTest,this.alphaHash=e.alphaHash,this.alphaToCoverage=e.alphaToCoverage,this.premultipliedAlpha=e.premultipliedAlpha,this.forceSinglePass=e.forceSinglePass,this.visible=e.visible,this.toneMapped=e.toneMapped,this.userData=JSON.parse(JSON.stringify(e.userData)),this}dispose(){this.dispatchEvent({type:"dispose"})}set needsUpdate(e){e===!0&&this.version++}},Ao=class extends Cr{constructor(e){super(),this.isMeshBasicMaterial=!0,this.type="MeshBasicMaterial",this.color=new it(16777215),this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.specularMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new Kn,this.combine=lh,this.reflectivity=1,this.refractionRatio=.98,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.specularMap=e.specularMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.combine=e.combine,this.reflectivity=e.reflectivity,this.refractionRatio=e.refractionRatio,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.fog=e.fog,this}};var Nt=new k,Va=new Ie,Gy=0,Cn=class{constructor(e,n,r=!1){if(Array.isArray(e))throw new TypeError("THREE.BufferAttribute: array should be a Typed Array.");this.isBufferAttribute=!0,Object.defineProperty(this,"id",{value:Gy++}),this.name="",this.array=e,this.itemSize=n,this.count=e!==void 0?e.length/n:0,this.normalized=r,this.usage=eh,this.updateRanges=[],this.gpuType=hr,this.version=0}onUploadCallback(){}set needsUpdate(e){e===!0&&this.version++}setUsage(e){return this.usage=e,this}addUpdateRange(e,n){this.updateRanges.push({start:e,count:n})}clearUpdateRanges(){this.updateRanges.length=0}copy(e){return this.name=e.name,this.array=new e.array.constructor(e.array),this.itemSize=e.itemSize,this.count=e.count,this.normalized=e.normalized,this.usage=e.usage,this.gpuType=e.gpuType,this}copyAt(e,n,r){e*=this.itemSize,r*=n.itemSize;for(let i=0,o=this.itemSize;i<o;i++)this.array[e+i]=n.array[r+i];return this}copyArray(e){return this.array.set(e),this}applyMatrix3(e){if(this.itemSize===2)for(let n=0,r=this.count;n<r;n++)Va.fromBufferAttribute(this,n),Va.applyMatrix3(e),this.setXY(n,Va.x,Va.y);else if(this.itemSize===3)for(let n=0,r=this.count;n<r;n++)Nt.fromBufferAttribute(this,n),Nt.applyMatrix3(e),this.setXYZ(n,Nt.x,Nt.y,Nt.z);return this}applyMatrix4(e){for(let n=0,r=this.count;n<r;n++)Nt.fromBufferAttribute(this,n),Nt.applyMatrix4(e),this.setXYZ(n,Nt.x,Nt.y,Nt.z);return this}applyNormalMatrix(e){for(let n=0,r=this.count;n<r;n++)Nt.fromBufferAttribute(this,n),Nt.applyNormalMatrix(e),this.setXYZ(n,Nt.x,Nt.y,Nt.z);return this}transformDirection(e){for(let n=0,r=this.count;n<r;n++)Nt.fromBufferAttribute(this,n),Nt.transformDirection(e),this.setXYZ(n,Nt.x,Nt.y,Nt.z);return this}set(e,n=0){return this.array.set(e,n),this}getComponent(e,n){let r=this.array[e*this.itemSize+n];return this.normalized&&(r=Mo(r,this.array)),r}setComponent(e,n,r){return this.normalized&&(r=ln(r,this.array)),this.array[e*this.itemSize+n]=r,this}getX(e){let n=this.array[e*this.itemSize];return this.normalized&&(n=Mo(n,this.array)),n}setX(e,n){return this.normalized&&(n=ln(n,this.array)),this.array[e*this.itemSize]=n,this}getY(e){let n=this.array[e*this.itemSize+1];return this.normalized&&(n=Mo(n,this.array)),n}setY(e,n){return this.normalized&&(n=ln(n,this.array)),this.array[e*this.itemSize+1]=n,this}getZ(e){let n=this.array[e*this.itemSize+2];return this.normalized&&(n=Mo(n,this.array)),n}setZ(e,n){return this.normalized&&(n=ln(n,this.array)),this.array[e*this.itemSize+2]=n,this}getW(e){let n=this.array[e*this.itemSize+3];return this.normalized&&(n=Mo(n,this.array)),n}setW(e,n){return this.normalized&&(n=ln(n,this.array)),this.array[e*this.itemSize+3]=n,this}setXY(e,n,r){return e*=this.itemSize,this.normalized&&(n=ln(n,this.array),r=ln(r,this.array)),this.array[e+0]=n,this.array[e+1]=r,this}setXYZ(e,n,r,i){return e*=this.itemSize,this.normalized&&(n=ln(n,this.array),r=ln(r,this.array),i=ln(i,this.array)),this.array[e+0]=n,this.array[e+1]=r,this.array[e+2]=i,this}setXYZW(e,n,r,i,o){return e*=this.itemSize,this.normalized&&(n=ln(n,this.array),r=ln(r,this.array),i=ln(i,this.array),o=ln(o,this.array)),this.array[e+0]=n,this.array[e+1]=r,this.array[e+2]=i,this.array[e+3]=o,this}onUpload(e){return this.onUploadCallback=e,this}clone(){return new this.constructor(this.array,this.itemSize).copy(this)}toJSON(){let e={itemSize:this.itemSize,type:this.array.constructor.name,array:Array.from(this.array),normalized:this.normalized};return this.name!==""&&(e.name=this.name),this.usage!==eh&&(e.usage=this.usage),e}};var Ds=class extends Cn{constructor(e,n,r){super(new Uint16Array(e),n,r)}};var As=class extends Cn{constructor(e,n,r){super(new Uint32Array(e),n,r)}};var qt=class extends Cn{constructor(e,n,r){super(new Float32Array(e),n,r)}},Wy=0,Un=new Rt,Vf=new Xt,vo=new k,Dn=new Jr,ps=new Jr,Wt=new k,cn=class t extends ur{constructor(){super(),this.isBufferGeometry=!0,Object.defineProperty(this,"id",{value:Wy++}),this.uuid=Oo(),this.name="",this.type="BufferGeometry",this.index=null,this.indirect=null,this.attributes={},this.morphAttributes={},this.morphTargetsRelative=!1,this.groups=[],this.boundingBox=null,this.boundingSphere=null,this.drawRange={start:0,count:1/0},this.userData={}}getIndex(){return this.index}setIndex(e){return Array.isArray(e)?this.index=new(bh(e)?As:Ds)(e,1):this.index=e,this}setIndirect(e){return this.indirect=e,this}getIndirect(){return this.indirect}getAttribute(e){return this.attributes[e]}setAttribute(e,n){return this.attributes[e]=n,this}deleteAttribute(e){return delete this.attributes[e],this}hasAttribute(e){return this.attributes[e]!==void 0}addGroup(e,n,r=0){this.groups.push({start:e,count:n,materialIndex:r})}clearGroups(){this.groups=[]}setDrawRange(e,n){this.drawRange.start=e,this.drawRange.count=n}applyMatrix4(e){let n=this.attributes.position;n!==void 0&&(n.applyMatrix4(e),n.needsUpdate=!0);let r=this.attributes.normal;if(r!==void 0){let o=new Ke().getNormalMatrix(e);r.applyNormalMatrix(o),r.needsUpdate=!0}let i=this.attributes.tangent;return i!==void 0&&(i.transformDirection(e),i.needsUpdate=!0),this.boundingBox!==null&&this.computeBoundingBox(),this.boundingSphere!==null&&this.computeBoundingSphere(),this}applyQuaternion(e){return Un.makeRotationFromQuaternion(e),this.applyMatrix4(Un),this}rotateX(e){return Un.makeRotationX(e),this.applyMatrix4(Un),this}rotateY(e){return Un.makeRotationY(e),this.applyMatrix4(Un),this}rotateZ(e){return Un.makeRotationZ(e),this.applyMatrix4(Un),this}translate(e,n,r){return Un.makeTranslation(e,n,r),this.applyMatrix4(Un),this}scale(e,n,r){return Un.makeScale(e,n,r),this.applyMatrix4(Un),this}lookAt(e){return Vf.lookAt(e),Vf.updateMatrix(),this.applyMatrix4(Vf.matrix),this}center(){return this.computeBoundingBox(),this.boundingBox.getCenter(vo).negate(),this.translate(vo.x,vo.y,vo.z),this}setFromPoints(e){let n=this.getAttribute("position");if(n===void 0){let r=[];for(let i=0,o=e.length;i<o;i++){let s=e[i];r.push(s.x,s.y,s.z||0)}this.setAttribute("position",new qt(r,3))}else{let r=Math.min(e.length,n.count);for(let i=0;i<r;i++){let o=e[i];n.setXYZ(i,o.x,o.y,o.z||0)}e.length>n.count&&console.warn("THREE.BufferGeometry: Buffer size too small for points data. Use .dispose() and create a new geometry."),n.needsUpdate=!0}return this}computeBoundingBox(){this.boundingBox===null&&(this.boundingBox=new Jr);let e=this.attributes.position,n=this.morphAttributes.position;if(e&&e.isGLBufferAttribute){console.error("THREE.BufferGeometry.computeBoundingBox(): GLBufferAttribute requires a manual bounding box.",this),this.boundingBox.set(new k(-1/0,-1/0,-1/0),new k(1/0,1/0,1/0));return}if(e!==void 0){if(this.boundingBox.setFromBufferAttribute(e),n)for(let r=0,i=n.length;r<i;r++){let o=n[r];Dn.setFromBufferAttribute(o),this.morphTargetsRelative?(Wt.addVectors(this.boundingBox.min,Dn.min),this.boundingBox.expandByPoint(Wt),Wt.addVectors(this.boundingBox.max,Dn.max),this.boundingBox.expandByPoint(Wt)):(this.boundingBox.expandByPoint(Dn.min),this.boundingBox.expandByPoint(Dn.max))}}else this.boundingBox.makeEmpty();(isNaN(this.boundingBox.min.x)||isNaN(this.boundingBox.min.y)||isNaN(this.boundingBox.min.z))&&console.error('THREE.BufferGeometry.computeBoundingBox(): Computed min/max have NaN values. The "position" attribute is likely to have NaN values.',this)}computeBoundingSphere(){this.boundingSphere===null&&(this.boundingSphere=new Ci);let e=this.attributes.position,n=this.morphAttributes.position;if(e&&e.isGLBufferAttribute){console.error("THREE.BufferGeometry.computeBoundingSphere(): GLBufferAttribute requires a manual bounding sphere.",this),this.boundingSphere.set(new k,1/0);return}if(e){let r=this.boundingSphere.center;if(Dn.setFromBufferAttribute(e),n)for(let o=0,s=n.length;o<s;o++){let a=n[o];ps.setFromBufferAttribute(a),this.morphTargetsRelative?(Wt.addVectors(Dn.min,ps.min),Dn.expandByPoint(Wt),Wt.addVectors(Dn.max,ps.max),Dn.expandByPoint(Wt)):(Dn.expandByPoint(ps.min),Dn.expandByPoint(ps.max))}Dn.getCenter(r);let i=0;for(let o=0,s=e.count;o<s;o++)Wt.fromBufferAttribute(e,o),i=Math.max(i,r.distanceToSquared(Wt));if(n)for(let o=0,s=n.length;o<s;o++){let a=n[o],l=this.morphTargetsRelative;for(let u=0,c=a.count;u<c;u++)Wt.fromBufferAttribute(a,u),l&&(vo.fromBufferAttribute(e,u),Wt.add(vo)),i=Math.max(i,r.distanceToSquared(Wt))}this.boundingSphere.radius=Math.sqrt(i),isNaN(this.boundingSphere.radius)&&console.error('THREE.BufferGeometry.computeBoundingSphere(): Computed radius is NaN. The "position" attribute is likely to have NaN values.',this)}}computeTangents(){let e=this.index,n=this.attributes;if(e===null||n.position===void 0||n.normal===void 0||n.uv===void 0){console.error("THREE.BufferGeometry: .computeTangents() failed. Missing required attributes (index, position, normal or uv)");return}let r=n.position,i=n.normal,o=n.uv;this.hasAttribute("tangent")===!1&&this.setAttribute("tangent",new Cn(new Float32Array(4*r.count),4));let s=this.getAttribute("tangent"),a=[],l=[];for(let D=0;D<r.count;D++)a[D]=new k,l[D]=new k;let u=new k,c=new k,f=new k,h=new Ie,d=new Ie,x=new Ie,p=new k,g=new k;function m(D,S,w){u.fromBufferAttribute(r,D),c.fromBufferAttribute(r,S),f.fromBufferAttribute(r,w),h.fromBufferAttribute(o,D),d.fromBufferAttribute(o,S),x.fromBufferAttribute(o,w),c.sub(u),f.sub(u),d.sub(h),x.sub(h);let C=1/(d.x*x.y-x.x*d.y);isFinite(C)&&(p.copy(c).multiplyScalar(x.y).addScaledVector(f,-d.y).multiplyScalar(C),g.copy(f).multiplyScalar(d.x).addScaledVector(c,-x.x).multiplyScalar(C),a[D].add(p),a[S].add(p),a[w].add(p),l[D].add(g),l[S].add(g),l[w].add(g))}let b=this.groups;b.length===0&&(b=[{start:0,count:e.count}]);for(let D=0,S=b.length;D<S;++D){let w=b[D],C=w.start,F=w.count;for(let O=C,U=C+F;O<U;O+=3)m(e.getX(O+0),e.getX(O+1),e.getX(O+2))}let v=new k,_=new k,M=new k,y=new k;function E(D){M.fromBufferAttribute(i,D),y.copy(M);let S=a[D];v.copy(S),v.sub(M.multiplyScalar(M.dot(S))).normalize(),_.crossVectors(y,S);let C=_.dot(l[D])<0?-1:1;s.setXYZW(D,v.x,v.y,v.z,C)}for(let D=0,S=b.length;D<S;++D){let w=b[D],C=w.start,F=w.count;for(let O=C,U=C+F;O<U;O+=3)E(e.getX(O+0)),E(e.getX(O+1)),E(e.getX(O+2))}}computeVertexNormals(){let e=this.index,n=this.getAttribute("position");if(n!==void 0){let r=this.getAttribute("normal");if(r===void 0)r=new Cn(new Float32Array(n.count*3),3),this.setAttribute("normal",r);else for(let h=0,d=r.count;h<d;h++)r.setXYZ(h,0,0,0);let i=new k,o=new k,s=new k,a=new k,l=new k,u=new k,c=new k,f=new k;if(e)for(let h=0,d=e.count;h<d;h+=3){let x=e.getX(h+0),p=e.getX(h+1),g=e.getX(h+2);i.fromBufferAttribute(n,x),o.fromBufferAttribute(n,p),s.fromBufferAttribute(n,g),c.subVectors(s,o),f.subVectors(i,o),c.cross(f),a.fromBufferAttribute(r,x),l.fromBufferAttribute(r,p),u.fromBufferAttribute(r,g),a.add(c),l.add(c),u.add(c),r.setXYZ(x,a.x,a.y,a.z),r.setXYZ(p,l.x,l.y,l.z),r.setXYZ(g,u.x,u.y,u.z)}else for(let h=0,d=n.count;h<d;h+=3)i.fromBufferAttribute(n,h+0),o.fromBufferAttribute(n,h+1),s.fromBufferAttribute(n,h+2),c.subVectors(s,o),f.subVectors(i,o),c.cross(f),r.setXYZ(h+0,c.x,c.y,c.z),r.setXYZ(h+1,c.x,c.y,c.z),r.setXYZ(h+2,c.x,c.y,c.z);this.normalizeNormals(),r.needsUpdate=!0}}normalizeNormals(){let e=this.attributes.normal;for(let n=0,r=e.count;n<r;n++)Wt.fromBufferAttribute(e,n),Wt.normalize(),e.setXYZ(n,Wt.x,Wt.y,Wt.z)}toNonIndexed(){function e(a,l){let u=a.array,c=a.itemSize,f=a.normalized,h=new u.constructor(l.length*c),d=0,x=0;for(let p=0,g=l.length;p<g;p++){a.isInterleavedBufferAttribute?d=l[p]*a.data.stride+a.offset:d=l[p]*c;for(let m=0;m<c;m++)h[x++]=u[d++]}return new Cn(h,c,f)}if(this.index===null)return console.warn("THREE.BufferGeometry.toNonIndexed(): BufferGeometry is already non-indexed."),this;let n=new t,r=this.index.array,i=this.attributes;for(let a in i){let l=i[a],u=e(l,r);n.setAttribute(a,u)}let o=this.morphAttributes;for(let a in o){let l=[],u=o[a];for(let c=0,f=u.length;c<f;c++){let h=u[c],d=e(h,r);l.push(d)}n.morphAttributes[a]=l}n.morphTargetsRelative=this.morphTargetsRelative;let s=this.groups;for(let a=0,l=s.length;a<l;a++){let u=s[a];n.addGroup(u.start,u.count,u.materialIndex)}return n}toJSON(){let e={metadata:{version:4.7,type:"BufferGeometry",generator:"BufferGeometry.toJSON"}};if(e.uuid=this.uuid,e.type=this.type,this.name!==""&&(e.name=this.name),Object.keys(this.userData).length>0&&(e.userData=this.userData),this.parameters!==void 0){let l=this.parameters;for(let u in l)l[u]!==void 0&&(e[u]=l[u]);return e}e.data={attributes:{}};let n=this.index;n!==null&&(e.data.index={type:n.array.constructor.name,array:Array.prototype.slice.call(n.array)});let r=this.attributes;for(let l in r){let u=r[l];e.data.attributes[l]=u.toJSON(e.data)}let i={},o=!1;for(let l in this.morphAttributes){let u=this.morphAttributes[l],c=[];for(let f=0,h=u.length;f<h;f++){let d=u[f];c.push(d.toJSON(e.data))}c.length>0&&(i[l]=c,o=!0)}o&&(e.data.morphAttributes=i,e.data.morphTargetsRelative=this.morphTargetsRelative);let s=this.groups;s.length>0&&(e.data.groups=JSON.parse(JSON.stringify(s)));let a=this.boundingSphere;return a!==null&&(e.data.boundingSphere=a.toJSON()),e}clone(){return new this.constructor().copy(this)}copy(e){this.index=null,this.attributes={},this.morphAttributes={},this.groups=[],this.boundingBox=null,this.boundingSphere=null;let n={};this.name=e.name;let r=e.index;r!==null&&this.setIndex(r.clone());let i=e.attributes;for(let u in i){let c=i[u];this.setAttribute(u,c.clone(n))}let o=e.morphAttributes;for(let u in o){let c=[],f=o[u];for(let h=0,d=f.length;h<d;h++)c.push(f[h].clone(n));this.morphAttributes[u]=c}this.morphTargetsRelative=e.morphTargetsRelative;let s=e.groups;for(let u=0,c=s.length;u<c;u++){let f=s[u];this.addGroup(f.start,f.count,f.materialIndex)}let a=e.boundingBox;a!==null&&(this.boundingBox=a.clone());let l=e.boundingSphere;return l!==null&&(this.boundingSphere=l.clone()),this.drawRange.start=e.drawRange.start,this.drawRange.count=e.drawRange.count,this.userData=e.userData,this}dispose(){this.dispatchEvent({type:"dispose"})}},lm=new Rt,Si=new Ti,Ha=new Ci,cm=new k,Ga=new k,Wa=new k,qa=new k,Hf=new k,Xa=new k,fm=new k,Ya=new k,Lt=class extends Xt{constructor(e=new cn,n=new Ao){super(),this.isMesh=!0,this.type="Mesh",this.geometry=e,this.material=n,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.count=1,this.updateMorphTargets()}copy(e,n){return super.copy(e,n),e.morphTargetInfluences!==void 0&&(this.morphTargetInfluences=e.morphTargetInfluences.slice()),e.morphTargetDictionary!==void 0&&(this.morphTargetDictionary=Object.assign({},e.morphTargetDictionary)),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}updateMorphTargets(){let n=this.geometry.morphAttributes,r=Object.keys(n);if(r.length>0){let i=n[r[0]];if(i!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let o=0,s=i.length;o<s;o++){let a=i[o].name||String(o);this.morphTargetInfluences.push(0),this.morphTargetDictionary[a]=o}}}}getVertexPosition(e,n){let r=this.geometry,i=r.attributes.position,o=r.morphAttributes.position,s=r.morphTargetsRelative;n.fromBufferAttribute(i,e);let a=this.morphTargetInfluences;if(o&&a){Xa.set(0,0,0);for(let l=0,u=o.length;l<u;l++){let c=a[l],f=o[l];c!==0&&(Hf.fromBufferAttribute(f,e),s?Xa.addScaledVector(Hf,c):Xa.addScaledVector(Hf.sub(n),c))}n.add(Xa)}return n}raycast(e,n){let r=this.geometry,i=this.material,o=this.matrixWorld;i!==void 0&&(r.boundingSphere===null&&r.computeBoundingSphere(),Ha.copy(r.boundingSphere),Ha.applyMatrix4(o),Si.copy(e.ray).recast(e.near),!(Ha.containsPoint(Si.origin)===!1&&(Si.intersectSphere(Ha,cm)===null||Si.origin.distanceToSquared(cm)>(e.far-e.near)**2))&&(lm.copy(o).invert(),Si.copy(e.ray).applyMatrix4(lm),!(r.boundingBox!==null&&Si.intersectsBox(r.boundingBox)===!1)&&this._computeIntersections(e,n,Si)))}_computeIntersections(e,n,r){let i,o=this.geometry,s=this.material,a=o.index,l=o.attributes.position,u=o.attributes.uv,c=o.attributes.uv1,f=o.attributes.normal,h=o.groups,d=o.drawRange;if(a!==null)if(Array.isArray(s))for(let x=0,p=h.length;x<p;x++){let g=h[x],m=s[g.materialIndex],b=Math.max(g.start,d.start),v=Math.min(a.count,Math.min(g.start+g.count,d.start+d.count));for(let _=b,M=v;_<M;_+=3){let y=a.getX(_),E=a.getX(_+1),D=a.getX(_+2);i=Za(this,m,e,r,u,c,f,y,E,D),i&&(i.faceIndex=Math.floor(_/3),i.face.materialIndex=g.materialIndex,n.push(i))}}else{let x=Math.max(0,d.start),p=Math.min(a.count,d.start+d.count);for(let g=x,m=p;g<m;g+=3){let b=a.getX(g),v=a.getX(g+1),_=a.getX(g+2);i=Za(this,s,e,r,u,c,f,b,v,_),i&&(i.faceIndex=Math.floor(g/3),n.push(i))}}else if(l!==void 0)if(Array.isArray(s))for(let x=0,p=h.length;x<p;x++){let g=h[x],m=s[g.materialIndex],b=Math.max(g.start,d.start),v=Math.min(l.count,Math.min(g.start+g.count,d.start+d.count));for(let _=b,M=v;_<M;_+=3){let y=_,E=_+1,D=_+2;i=Za(this,m,e,r,u,c,f,y,E,D),i&&(i.faceIndex=Math.floor(_/3),i.face.materialIndex=g.materialIndex,n.push(i))}}else{let x=Math.max(0,d.start),p=Math.min(l.count,d.start+d.count);for(let g=x,m=p;g<m;g+=3){let b=g,v=g+1,_=g+2;i=Za(this,s,e,r,u,c,f,b,v,_),i&&(i.faceIndex=Math.floor(g/3),n.push(i))}}}};function qy(t,e,n,r,i,o,s,a){let l;if(e.side===fn?l=r.intersectTriangle(s,o,i,!0,a):l=r.intersectTriangle(i,o,s,e.side===Ar,a),l===null)return null;Ya.copy(a),Ya.applyMatrix4(t.matrixWorld);let u=n.ray.origin.distanceTo(Ya);return u<n.near||u>n.far?null:{distance:u,point:Ya.clone(),object:t}}function Za(t,e,n,r,i,o,s,a,l,u){t.getVertexPosition(a,Ga),t.getVertexPosition(l,Wa),t.getVertexPosition(u,qa);let c=qy(t,e,n,r,Ga,Wa,qa,fm);if(c){let f=new k;Yr.getBarycoord(fm,Ga,Wa,qa,f),i&&(c.uv=Yr.getInterpolatedAttribute(i,a,l,u,f,new Ie)),o&&(c.uv1=Yr.getInterpolatedAttribute(o,a,l,u,f,new Ie)),s&&(c.normal=Yr.getInterpolatedAttribute(s,a,l,u,f,new k),c.normal.dot(r.direction)>0&&c.normal.multiplyScalar(-1));let h={a,b:l,c:u,normal:new k,materialIndex:0};Yr.getNormal(Ga,Wa,qa,h.normal),c.face=h,c.barycoord=f}return c}var Qn=class t extends cn{constructor(e=1,n=1,r=1,i=1,o=1,s=1){super(),this.type="BoxGeometry",this.parameters={width:e,height:n,depth:r,widthSegments:i,heightSegments:o,depthSegments:s};let a=this;i=Math.floor(i),o=Math.floor(o),s=Math.floor(s);let l=[],u=[],c=[],f=[],h=0,d=0;x("z","y","x",-1,-1,r,n,e,s,o,0),x("z","y","x",1,-1,r,n,-e,s,o,1),x("x","z","y",1,1,e,r,n,i,s,2),x("x","z","y",1,-1,e,r,-n,i,s,3),x("x","y","z",1,-1,e,n,r,i,o,4),x("x","y","z",-1,-1,e,n,-r,i,o,5),this.setIndex(l),this.setAttribute("position",new qt(u,3)),this.setAttribute("normal",new qt(c,3)),this.setAttribute("uv",new qt(f,2));function x(p,g,m,b,v,_,M,y,E,D,S){let w=_/E,C=M/D,F=_/2,O=M/2,U=y/2,z=E+1,B=D+1,J=0,H=0,ne=new k;for(let se=0;se<B;se++){let ge=se*C-O;for(let Te=0;Te<z;Te++){let ze=Te*w-F;ne[p]=ze*b,ne[g]=ge*v,ne[m]=U,u.push(ne.x,ne.y,ne.z),ne[p]=0,ne[g]=0,ne[m]=y>0?1:-1,c.push(ne.x,ne.y,ne.z),f.push(Te/E),f.push(1-se/D),J+=1}}for(let se=0;se<D;se++)for(let ge=0;ge<E;ge++){let Te=h+ge+z*se,ze=h+ge+z*(se+1),Ze=h+(ge+1)+z*(se+1),ke=h+(ge+1)+z*se;l.push(Te,ze,ke),l.push(ze,Ze,ke),H+=6}a.addGroup(d,H,S),d+=H,h+=J}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new t(e.width,e.height,e.depth,e.widthSegments,e.heightSegments,e.depthSegments)}};function Ni(t){let e={};for(let n in t){e[n]={};for(let r in t[n]){let i=t[n][r];i&&(i.isColor||i.isMatrix3||i.isMatrix4||i.isVector2||i.isVector3||i.isVector4||i.isTexture||i.isQuaternion)?i.isRenderTargetTexture?(console.warn("UniformsUtils: Textures of render targets cannot be cloned via cloneUniforms() or mergeUniforms()."),e[n][r]=null):e[n][r]=i.clone():Array.isArray(i)?e[n][r]=i.slice():e[n][r]=i}}return e}function nn(t){let e={};for(let n=0;n<t.length;n++){let r=Ni(t[n]);for(let i in r)e[i]=r[i]}return e}function Xy(t){let e=[];for(let n=0;n<t.length;n++)e.push(t[n].clone());return e}function Eh(t){let e=t.getRenderTarget();return e===null?t.outputColorSpace:e.isXRRenderTarget===!0?e.texture.colorSpace:ct.workingColorSpace}var cg={clone:Ni,merge:nn},Yy=`void main() {
	gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );
}`,Zy=`void main() {
	gl_FragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}`,jn=class extends Cr{constructor(e){super(),this.isShaderMaterial=!0,this.type="ShaderMaterial",this.defines={},this.uniforms={},this.uniformsGroups=[],this.vertexShader=Yy,this.fragmentShader=Zy,this.linewidth=1,this.wireframe=!1,this.wireframeLinewidth=1,this.fog=!1,this.lights=!1,this.clipping=!1,this.forceSinglePass=!0,this.extensions={clipCullDistance:!1,multiDraw:!1},this.defaultAttributeValues={color:[1,1,1],uv:[0,0],uv1:[0,0]},this.index0AttributeName=void 0,this.uniformsNeedUpdate=!1,this.glslVersion=null,e!==void 0&&this.setValues(e)}copy(e){return super.copy(e),this.fragmentShader=e.fragmentShader,this.vertexShader=e.vertexShader,this.uniforms=Ni(e.uniforms),this.uniformsGroups=Xy(e.uniformsGroups),this.defines=Object.assign({},e.defines),this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.fog=e.fog,this.lights=e.lights,this.clipping=e.clipping,this.extensions=Object.assign({},e.extensions),this.glslVersion=e.glslVersion,this}toJSON(e){let n=super.toJSON(e);n.glslVersion=this.glslVersion,n.uniforms={};for(let i in this.uniforms){let s=this.uniforms[i].value;s&&s.isTexture?n.uniforms[i]={type:"t",value:s.toJSON(e).uuid}:s&&s.isColor?n.uniforms[i]={type:"c",value:s.getHex()}:s&&s.isVector2?n.uniforms[i]={type:"v2",value:s.toArray()}:s&&s.isVector3?n.uniforms[i]={type:"v3",value:s.toArray()}:s&&s.isVector4?n.uniforms[i]={type:"v4",value:s.toArray()}:s&&s.isMatrix3?n.uniforms[i]={type:"m3",value:s.toArray()}:s&&s.isMatrix4?n.uniforms[i]={type:"m4",value:s.toArray()}:n.uniforms[i]={value:s}}Object.keys(this.defines).length>0&&(n.defines=this.defines),n.vertexShader=this.vertexShader,n.fragmentShader=this.fragmentShader,n.lights=this.lights,n.clipping=this.clipping;let r={};for(let i in this.extensions)this.extensions[i]===!0&&(r[i]=!0);return Object.keys(r).length>0&&(n.extensions=r),n}},Cs=class extends Xt{constructor(){super(),this.isCamera=!0,this.type="Camera",this.matrixWorldInverse=new Rt,this.projectionMatrix=new Rt,this.projectionMatrixInverse=new Rt,this.coordinateSystem=$n,this._reversedDepth=!1}get reversedDepth(){return this._reversedDepth}copy(e,n){return super.copy(e,n),this.matrixWorldInverse.copy(e.matrixWorldInverse),this.projectionMatrix.copy(e.projectionMatrix),this.projectionMatrixInverse.copy(e.projectionMatrixInverse),this.coordinateSystem=e.coordinateSystem,this}getWorldDirection(e){return super.getWorldDirection(e).negate()}updateMatrixWorld(e){super.updateMatrixWorld(e),this.matrixWorldInverse.copy(this.matrixWorld).invert()}updateWorldMatrix(e,n){super.updateWorldMatrix(e,n),this.matrixWorldInverse.copy(this.matrixWorld).invert()}clone(){return new this.constructor().copy(this)}},Xr=new k,hm=new Ie,dm=new Ie,tn=class extends Cs{constructor(e=50,n=1,r=.1,i=2e3){super(),this.isPerspectiveCamera=!0,this.type="PerspectiveCamera",this.fov=e,this.zoom=1,this.near=r,this.far=i,this.focus=10,this.aspect=n,this.view=null,this.filmGauge=35,this.filmOffset=0,this.updateProjectionMatrix()}copy(e,n){return super.copy(e,n),this.fov=e.fov,this.zoom=e.zoom,this.near=e.near,this.far=e.far,this.focus=e.focus,this.aspect=e.aspect,this.view=e.view===null?null:Object.assign({},e.view),this.filmGauge=e.filmGauge,this.filmOffset=e.filmOffset,this}setFocalLength(e){let n=.5*this.getFilmHeight()/e;this.fov=bo*2*Math.atan(n),this.updateProjectionMatrix()}getFocalLength(){let e=Math.tan(gs*.5*this.fov);return .5*this.getFilmHeight()/e}getEffectiveFOV(){return bo*2*Math.atan(Math.tan(gs*.5*this.fov)/this.zoom)}getFilmWidth(){return this.filmGauge*Math.min(this.aspect,1)}getFilmHeight(){return this.filmGauge/Math.max(this.aspect,1)}getViewBounds(e,n,r){Xr.set(-1,-1,.5).applyMatrix4(this.projectionMatrixInverse),n.set(Xr.x,Xr.y).multiplyScalar(-e/Xr.z),Xr.set(1,1,.5).applyMatrix4(this.projectionMatrixInverse),r.set(Xr.x,Xr.y).multiplyScalar(-e/Xr.z)}getViewSize(e,n){return this.getViewBounds(e,hm,dm),n.subVectors(dm,hm)}setViewOffset(e,n,r,i,o,s){this.aspect=e/n,this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=n,this.view.offsetX=r,this.view.offsetY=i,this.view.width=o,this.view.height=s,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=this.near,n=e*Math.tan(gs*.5*this.fov)/this.zoom,r=2*n,i=this.aspect*r,o=-.5*i,s=this.view;if(this.view!==null&&this.view.enabled){let l=s.fullWidth,u=s.fullHeight;o+=s.offsetX*i/l,n-=s.offsetY*r/u,i*=s.width/l,r*=s.height/u}let a=this.filmOffset;a!==0&&(o+=e*a/this.getFilmWidth()),this.projectionMatrix.makePerspective(o,o+i,n,n-r,e,this.far,this.coordinateSystem,this.reversedDepth),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let n=super.toJSON(e);return n.object.fov=this.fov,n.object.zoom=this.zoom,n.object.near=this.near,n.object.far=this.far,n.object.focus=this.focus,n.object.aspect=this.aspect,this.view!==null&&(n.object.view=Object.assign({},this.view)),n.object.filmGauge=this.filmGauge,n.object.filmOffset=this.filmOffset,n}},_o=-90,yo=1,cu=class extends Xt{constructor(e,n,r){super(),this.type="CubeCamera",this.renderTarget=r,this.coordinateSystem=null,this.activeMipmapLevel=0;let i=new tn(_o,yo,e,n);i.layers=this.layers,this.add(i);let o=new tn(_o,yo,e,n);o.layers=this.layers,this.add(o);let s=new tn(_o,yo,e,n);s.layers=this.layers,this.add(s);let a=new tn(_o,yo,e,n);a.layers=this.layers,this.add(a);let l=new tn(_o,yo,e,n);l.layers=this.layers,this.add(l);let u=new tn(_o,yo,e,n);u.layers=this.layers,this.add(u)}updateCoordinateSystem(){let e=this.coordinateSystem,n=this.children.concat(),[r,i,o,s,a,l]=n;for(let u of n)this.remove(u);if(e===$n)r.up.set(0,1,0),r.lookAt(1,0,0),i.up.set(0,1,0),i.lookAt(-1,0,0),o.up.set(0,0,-1),o.lookAt(0,1,0),s.up.set(0,0,1),s.lookAt(0,-1,0),a.up.set(0,1,0),a.lookAt(0,0,1),l.up.set(0,1,0),l.lookAt(0,0,-1);else if(e===Ss)r.up.set(0,-1,0),r.lookAt(-1,0,0),i.up.set(0,-1,0),i.lookAt(1,0,0),o.up.set(0,0,1),o.lookAt(0,1,0),s.up.set(0,0,-1),s.lookAt(0,-1,0),a.up.set(0,-1,0),a.lookAt(0,0,1),l.up.set(0,-1,0),l.lookAt(0,0,-1);else throw new Error("THREE.CubeCamera.updateCoordinateSystem(): Invalid coordinate system: "+e);for(let u of n)this.add(u),u.updateMatrixWorld()}update(e,n){this.parent===null&&this.updateMatrixWorld();let{renderTarget:r,activeMipmapLevel:i}=this;this.coordinateSystem!==e.coordinateSystem&&(this.coordinateSystem=e.coordinateSystem,this.updateCoordinateSystem());let[o,s,a,l,u,c]=this.children,f=e.getRenderTarget(),h=e.getActiveCubeFace(),d=e.getActiveMipmapLevel(),x=e.xr.enabled;e.xr.enabled=!1;let p=r.texture.generateMipmaps;r.texture.generateMipmaps=!1,e.setRenderTarget(r,0,i),e.render(n,o),e.setRenderTarget(r,1,i),e.render(n,s),e.setRenderTarget(r,2,i),e.render(n,a),e.setRenderTarget(r,3,i),e.render(n,l),e.setRenderTarget(r,4,i),e.render(n,u),r.texture.generateMipmaps=p,e.setRenderTarget(r,5,i),e.render(n,c),e.setRenderTarget(f,h,d),e.xr.enabled=x,r.texture.needsPMREMUpdate=!0}},Ts=class extends Tn{constructor(e=[],n=Pi,r,i,o,s,a,l,u,c){super(e,n,r,i,o,s,a,l,u,c),this.isCubeTexture=!0,this.flipY=!1}get images(){return this.image}set images(e){this.image=e}},fu=class extends lr{constructor(e=1,n={}){super(e,e,n),this.isWebGLCubeRenderTarget=!0;let r={width:e,height:e,depth:1},i=[r,r,r,r,r,r];this.texture=new Ts(i),this._setTextureOptions(n),this.texture.isRenderTargetTexture=!0}fromEquirectangularTexture(e,n){this.texture.type=n.type,this.texture.colorSpace=n.colorSpace,this.texture.generateMipmaps=n.generateMipmaps,this.texture.minFilter=n.minFilter,this.texture.magFilter=n.magFilter;let r={uniforms:{tEquirect:{value:null}},vertexShader:`

				varying vec3 vWorldDirection;

				vec3 transformDirection( in vec3 dir, in mat4 matrix ) {

					return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );

				}

				void main() {

					vWorldDirection = transformDirection( position, modelMatrix );

					#include <begin_vertex>
					#include <project_vertex>

				}
			`,fragmentShader:`

				uniform sampler2D tEquirect;

				varying vec3 vWorldDirection;

				#include <common>

				void main() {

					vec3 direction = normalize( vWorldDirection );

					vec2 sampleUV = equirectUv( direction );

					gl_FragColor = texture2D( tEquirect, sampleUV );

				}
			`},i=new Qn(5,5,5),o=new jn({name:"CubemapFromEquirect",uniforms:Ni(r.uniforms),vertexShader:r.vertexShader,fragmentShader:r.fragmentShader,side:fn,blending:Tr});o.uniforms.tEquirect.value=n;let s=new Lt(i,o),a=n.minFilter;return n.minFilter===ti&&(n.minFilter=Jn),new cu(1,10,this).update(e,s),n.minFilter=a,s.geometry.dispose(),s.material.dispose(),this}clear(e,n=!0,r=!0,i=!0){let o=e.getRenderTarget();for(let s=0;s<6;s++)e.setRenderTarget(this,s),e.clear(n,r,i);e.setRenderTarget(o)}},Er=class extends Xt{constructor(){super(),this.isGroup=!0,this.type="Group"}},$y={type:"move"},Co=class{constructor(){this._targetRay=null,this._grip=null,this._hand=null}getHandSpace(){return this._hand===null&&(this._hand=new Er,this._hand.matrixAutoUpdate=!1,this._hand.visible=!1,this._hand.joints={},this._hand.inputState={pinching:!1}),this._hand}getTargetRaySpace(){return this._targetRay===null&&(this._targetRay=new Er,this._targetRay.matrixAutoUpdate=!1,this._targetRay.visible=!1,this._targetRay.hasLinearVelocity=!1,this._targetRay.linearVelocity=new k,this._targetRay.hasAngularVelocity=!1,this._targetRay.angularVelocity=new k),this._targetRay}getGripSpace(){return this._grip===null&&(this._grip=new Er,this._grip.matrixAutoUpdate=!1,this._grip.visible=!1,this._grip.hasLinearVelocity=!1,this._grip.linearVelocity=new k,this._grip.hasAngularVelocity=!1,this._grip.angularVelocity=new k),this._grip}dispatchEvent(e){return this._targetRay!==null&&this._targetRay.dispatchEvent(e),this._grip!==null&&this._grip.dispatchEvent(e),this._hand!==null&&this._hand.dispatchEvent(e),this}connect(e){if(e&&e.hand){let n=this._hand;if(n)for(let r of e.hand.values())this._getHandJoint(n,r)}return this.dispatchEvent({type:"connected",data:e}),this}disconnect(e){return this.dispatchEvent({type:"disconnected",data:e}),this._targetRay!==null&&(this._targetRay.visible=!1),this._grip!==null&&(this._grip.visible=!1),this._hand!==null&&(this._hand.visible=!1),this}update(e,n,r){let i=null,o=null,s=null,a=this._targetRay,l=this._grip,u=this._hand;if(e&&n.session.visibilityState!=="visible-blurred"){if(u&&e.hand){s=!0;for(let p of e.hand.values()){let g=n.getJointPose(p,r),m=this._getHandJoint(u,p);g!==null&&(m.matrix.fromArray(g.transform.matrix),m.matrix.decompose(m.position,m.rotation,m.scale),m.matrixWorldNeedsUpdate=!0,m.jointRadius=g.radius),m.visible=g!==null}let c=u.joints["index-finger-tip"],f=u.joints["thumb-tip"],h=c.position.distanceTo(f.position),d=.02,x=.005;u.inputState.pinching&&h>d+x?(u.inputState.pinching=!1,this.dispatchEvent({type:"pinchend",handedness:e.handedness,target:this})):!u.inputState.pinching&&h<=d-x&&(u.inputState.pinching=!0,this.dispatchEvent({type:"pinchstart",handedness:e.handedness,target:this}))}else l!==null&&e.gripSpace&&(o=n.getPose(e.gripSpace,r),o!==null&&(l.matrix.fromArray(o.transform.matrix),l.matrix.decompose(l.position,l.rotation,l.scale),l.matrixWorldNeedsUpdate=!0,o.linearVelocity?(l.hasLinearVelocity=!0,l.linearVelocity.copy(o.linearVelocity)):l.hasLinearVelocity=!1,o.angularVelocity?(l.hasAngularVelocity=!0,l.angularVelocity.copy(o.angularVelocity)):l.hasAngularVelocity=!1));a!==null&&(i=n.getPose(e.targetRaySpace,r),i===null&&o!==null&&(i=o),i!==null&&(a.matrix.fromArray(i.transform.matrix),a.matrix.decompose(a.position,a.rotation,a.scale),a.matrixWorldNeedsUpdate=!0,i.linearVelocity?(a.hasLinearVelocity=!0,a.linearVelocity.copy(i.linearVelocity)):a.hasLinearVelocity=!1,i.angularVelocity?(a.hasAngularVelocity=!0,a.angularVelocity.copy(i.angularVelocity)):a.hasAngularVelocity=!1,this.dispatchEvent($y)))}return a!==null&&(a.visible=i!==null),l!==null&&(l.visible=o!==null),u!==null&&(u.visible=s!==null),this}_getHandJoint(e,n){if(e.joints[n.jointName]===void 0){let r=new Er;r.matrixAutoUpdate=!1,r.visible=!1,e.joints[n.jointName]=r,e.add(r)}return e.joints[n.jointName]}};var Rs=class extends Xt{constructor(){super(),this.isScene=!0,this.type="Scene",this.background=null,this.environment=null,this.fog=null,this.backgroundBlurriness=0,this.backgroundIntensity=1,this.backgroundRotation=new Kn,this.environmentIntensity=1,this.environmentRotation=new Kn,this.overrideMaterial=null,typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}copy(e,n){return super.copy(e,n),e.background!==null&&(this.background=e.background.clone()),e.environment!==null&&(this.environment=e.environment.clone()),e.fog!==null&&(this.fog=e.fog.clone()),this.backgroundBlurriness=e.backgroundBlurriness,this.backgroundIntensity=e.backgroundIntensity,this.backgroundRotation.copy(e.backgroundRotation),this.environmentIntensity=e.environmentIntensity,this.environmentRotation.copy(e.environmentRotation),e.overrideMaterial!==null&&(this.overrideMaterial=e.overrideMaterial.clone()),this.matrixAutoUpdate=e.matrixAutoUpdate,this}toJSON(e){let n=super.toJSON(e);return this.fog!==null&&(n.object.fog=this.fog.toJSON()),this.backgroundBlurriness>0&&(n.object.backgroundBlurriness=this.backgroundBlurriness),this.backgroundIntensity!==1&&(n.object.backgroundIntensity=this.backgroundIntensity),n.object.backgroundRotation=this.backgroundRotation.toArray(),this.environmentIntensity!==1&&(n.object.environmentIntensity=this.environmentIntensity),n.object.environmentRotation=this.environmentRotation.toArray(),n}};var Gf=new k,Jy=new k,Ky=new Ke,On=class{constructor(e=new k(1,0,0),n=0){this.isPlane=!0,this.normal=e,this.constant=n}set(e,n){return this.normal.copy(e),this.constant=n,this}setComponents(e,n,r,i){return this.normal.set(e,n,r),this.constant=i,this}setFromNormalAndCoplanarPoint(e,n){return this.normal.copy(e),this.constant=-n.dot(this.normal),this}setFromCoplanarPoints(e,n,r){let i=Gf.subVectors(r,n).cross(Jy.subVectors(e,n)).normalize();return this.setFromNormalAndCoplanarPoint(i,e),this}copy(e){return this.normal.copy(e.normal),this.constant=e.constant,this}normalize(){let e=1/this.normal.length();return this.normal.multiplyScalar(e),this.constant*=e,this}negate(){return this.constant*=-1,this.normal.negate(),this}distanceToPoint(e){return this.normal.dot(e)+this.constant}distanceToSphere(e){return this.distanceToPoint(e.center)-e.radius}projectPoint(e,n){return n.copy(e).addScaledVector(this.normal,-this.distanceToPoint(e))}intersectLine(e,n){let r=e.delta(Gf),i=this.normal.dot(r);if(i===0)return this.distanceToPoint(e.start)===0?n.copy(e.start):null;let o=-(e.start.dot(this.normal)+this.constant)/i;return o<0||o>1?null:n.copy(e.start).addScaledVector(r,o)}intersectsLine(e){let n=this.distanceToPoint(e.start),r=this.distanceToPoint(e.end);return n<0&&r>0||r<0&&n>0}intersectsBox(e){return e.intersectsPlane(this)}intersectsSphere(e){return e.intersectsPlane(this)}coplanarPoint(e){return e.copy(this.normal).multiplyScalar(-this.constant)}applyMatrix4(e,n){let r=n||Ky.getNormalMatrix(e),i=this.coplanarPoint(Gf).applyMatrix4(e),o=this.normal.applyMatrix3(r).normalize();return this.constant=-i.dot(o),this}translate(e){return this.constant-=e.dot(this.normal),this}equals(e){return e.normal.equals(this.normal)&&e.constant===this.constant}clone(){return new this.constructor().copy(this)}},wi=new Ci,Qy=new Ie(.5,.5),$a=new k,To=class{constructor(e=new On,n=new On,r=new On,i=new On,o=new On,s=new On){this.planes=[e,n,r,i,o,s]}set(e,n,r,i,o,s){let a=this.planes;return a[0].copy(e),a[1].copy(n),a[2].copy(r),a[3].copy(i),a[4].copy(o),a[5].copy(s),this}copy(e){let n=this.planes;for(let r=0;r<6;r++)n[r].copy(e.planes[r]);return this}setFromProjectionMatrix(e,n=$n,r=!1){let i=this.planes,o=e.elements,s=o[0],a=o[1],l=o[2],u=o[3],c=o[4],f=o[5],h=o[6],d=o[7],x=o[8],p=o[9],g=o[10],m=o[11],b=o[12],v=o[13],_=o[14],M=o[15];if(i[0].setComponents(u-s,d-c,m-x,M-b).normalize(),i[1].setComponents(u+s,d+c,m+x,M+b).normalize(),i[2].setComponents(u+a,d+f,m+p,M+v).normalize(),i[3].setComponents(u-a,d-f,m-p,M-v).normalize(),r)i[4].setComponents(l,h,g,_).normalize(),i[5].setComponents(u-l,d-h,m-g,M-_).normalize();else if(i[4].setComponents(u-l,d-h,m-g,M-_).normalize(),n===$n)i[5].setComponents(u+l,d+h,m+g,M+_).normalize();else if(n===Ss)i[5].setComponents(l,h,g,_).normalize();else throw new Error("THREE.Frustum.setFromProjectionMatrix(): Invalid coordinate system: "+n);return this}intersectsObject(e){if(e.boundingSphere!==void 0)e.boundingSphere===null&&e.computeBoundingSphere(),wi.copy(e.boundingSphere).applyMatrix4(e.matrixWorld);else{let n=e.geometry;n.boundingSphere===null&&n.computeBoundingSphere(),wi.copy(n.boundingSphere).applyMatrix4(e.matrixWorld)}return this.intersectsSphere(wi)}intersectsSprite(e){wi.center.set(0,0,0);let n=Qy.distanceTo(e.center);return wi.radius=.7071067811865476+n,wi.applyMatrix4(e.matrixWorld),this.intersectsSphere(wi)}intersectsSphere(e){let n=this.planes,r=e.center,i=-e.radius;for(let o=0;o<6;o++)if(n[o].distanceToPoint(r)<i)return!1;return!0}intersectsBox(e){let n=this.planes;for(let r=0;r<6;r++){let i=n[r];if($a.x=i.normal.x>0?e.max.x:e.min.x,$a.y=i.normal.y>0?e.max.y:e.min.y,$a.z=i.normal.z>0?e.max.z:e.min.z,i.distanceToPoint($a)<0)return!1}return!0}containsPoint(e){let n=this.planes;for(let r=0;r<6;r++)if(n[r].distanceToPoint(e)<0)return!1;return!0}clone(){return new this.constructor().copy(this)}};var Ro=class extends Cr{constructor(e){super(),this.isLineBasicMaterial=!0,this.type="LineBasicMaterial",this.color=new it(16777215),this.map=null,this.linewidth=1,this.linecap="round",this.linejoin="round",this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.color.copy(e.color),this.map=e.map,this.linewidth=e.linewidth,this.linecap=e.linecap,this.linejoin=e.linejoin,this.fog=e.fog,this}},hu=new k,du=new k,pm=new Rt,ms=new Ti,Ja=new Ci,Wf=new k,mm=new k,Fo=class extends Xt{constructor(e=new cn,n=new Ro){super(),this.isLine=!0,this.type="Line",this.geometry=e,this.material=n,this.morphTargetDictionary=void 0,this.morphTargetInfluences=void 0,this.updateMorphTargets()}copy(e,n){return super.copy(e,n),this.material=Array.isArray(e.material)?e.material.slice():e.material,this.geometry=e.geometry,this}computeLineDistances(){let e=this.geometry;if(e.index===null){let n=e.attributes.position,r=[0];for(let i=1,o=n.count;i<o;i++)hu.fromBufferAttribute(n,i-1),du.fromBufferAttribute(n,i),r[i]=r[i-1],r[i]+=hu.distanceTo(du);e.setAttribute("lineDistance",new qt(r,1))}else console.warn("THREE.Line.computeLineDistances(): Computation only possible with non-indexed BufferGeometry.");return this}raycast(e,n){let r=this.geometry,i=this.matrixWorld,o=e.params.Line.threshold,s=r.drawRange;if(r.boundingSphere===null&&r.computeBoundingSphere(),Ja.copy(r.boundingSphere),Ja.applyMatrix4(i),Ja.radius+=o,e.ray.intersectsSphere(Ja)===!1)return;pm.copy(i).invert(),ms.copy(e.ray).applyMatrix4(pm);let a=o/((this.scale.x+this.scale.y+this.scale.z)/3),l=a*a,u=this.isLineSegments?2:1,c=r.index,h=r.attributes.position;if(c!==null){let d=Math.max(0,s.start),x=Math.min(c.count,s.start+s.count);for(let p=d,g=x-1;p<g;p+=u){let m=c.getX(p),b=c.getX(p+1),v=Ka(this,e,ms,l,m,b,p);v&&n.push(v)}if(this.isLineLoop){let p=c.getX(x-1),g=c.getX(d),m=Ka(this,e,ms,l,p,g,x-1);m&&n.push(m)}}else{let d=Math.max(0,s.start),x=Math.min(h.count,s.start+s.count);for(let p=d,g=x-1;p<g;p+=u){let m=Ka(this,e,ms,l,p,p+1,p);m&&n.push(m)}if(this.isLineLoop){let p=Ka(this,e,ms,l,x-1,d,x-1);p&&n.push(p)}}}updateMorphTargets(){let n=this.geometry.morphAttributes,r=Object.keys(n);if(r.length>0){let i=n[r[0]];if(i!==void 0){this.morphTargetInfluences=[],this.morphTargetDictionary={};for(let o=0,s=i.length;o<s;o++){let a=i[o].name||String(o);this.morphTargetInfluences.push(0),this.morphTargetDictionary[a]=o}}}}};function Ka(t,e,n,r,i,o,s){let a=t.geometry.attributes.position;if(hu.fromBufferAttribute(a,i),du.fromBufferAttribute(a,o),n.distanceSqToSegment(hu,du,Wf,mm)>r)return;Wf.applyMatrix4(t.matrixWorld);let u=e.ray.origin.distanceTo(Wf);if(!(u<e.near||u>e.far))return{distance:u,point:mm.clone().applyMatrix4(t.matrixWorld),index:s,face:null,faceIndex:null,barycoord:null,object:t}}var Fs=class extends Tn{constructor(e,n,r=ni,i,o,s,a=zn,l=zn,u,c=wo,f=1){if(c!==wo&&c!==Uo)throw new Error("DepthTexture format must be either THREE.DepthFormat or THREE.DepthStencilFormat");let h={width:e,height:n,depth:f};super(h,i,o,s,a,l,c,r,u),this.isDepthTexture=!0,this.flipY=!1,this.generateMipmaps=!1,this.compareFunction=null}copy(e){return super.copy(e),this.source=new Do(Object.assign({},e.image)),this.compareFunction=e.compareFunction,this}toJSON(e){let n=super.toJSON(e);return this.compareFunction!==null&&(n.compareFunction=this.compareFunction),n}},Ps=class extends Tn{constructor(e=null){super(),this.sourceTexture=e,this.isExternalTexture=!0}copy(e){return super.copy(e),this.sourceTexture=e.sourceTexture,this}};var pu=class t extends cn{constructor(e=1,n=1,r=1,i=32,o=1,s=!1,a=0,l=Math.PI*2){super(),this.type="CylinderGeometry",this.parameters={radiusTop:e,radiusBottom:n,height:r,radialSegments:i,heightSegments:o,openEnded:s,thetaStart:a,thetaLength:l};let u=this;i=Math.floor(i),o=Math.floor(o);let c=[],f=[],h=[],d=[],x=0,p=[],g=r/2,m=0;b(),s===!1&&(e>0&&v(!0),n>0&&v(!1)),this.setIndex(c),this.setAttribute("position",new qt(f,3)),this.setAttribute("normal",new qt(h,3)),this.setAttribute("uv",new qt(d,2));function b(){let _=new k,M=new k,y=0,E=(n-e)/r;for(let D=0;D<=o;D++){let S=[],w=D/o,C=w*(n-e)+e;for(let F=0;F<=i;F++){let O=F/i,U=O*l+a,z=Math.sin(U),B=Math.cos(U);M.x=C*z,M.y=-w*r+g,M.z=C*B,f.push(M.x,M.y,M.z),_.set(z,E,B).normalize(),h.push(_.x,_.y,_.z),d.push(O,1-w),S.push(x++)}p.push(S)}for(let D=0;D<i;D++)for(let S=0;S<o;S++){let w=p[S][D],C=p[S+1][D],F=p[S+1][D+1],O=p[S][D+1];(e>0||S!==0)&&(c.push(w,C,O),y+=3),(n>0||S!==o-1)&&(c.push(C,F,O),y+=3)}u.addGroup(m,y,0),m+=y}function v(_){let M=x,y=new Ie,E=new k,D=0,S=_===!0?e:n,w=_===!0?1:-1;for(let F=1;F<=i;F++)f.push(0,g*w,0),h.push(0,w,0),d.push(.5,.5),x++;let C=x;for(let F=0;F<=i;F++){let U=F/i*l+a,z=Math.cos(U),B=Math.sin(U);E.x=S*B,E.y=g*w,E.z=S*z,f.push(E.x,E.y,E.z),h.push(0,w,0),y.x=z*.5+.5,y.y=B*.5*w+.5,d.push(y.x,y.y),x++}for(let F=0;F<i;F++){let O=M+F,U=C+F;_===!0?c.push(U,U+1,O):c.push(U+1,U,O),D+=3}u.addGroup(m,D,_===!0?1:2),m+=D}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new t(e.radiusTop,e.radiusBottom,e.height,e.radialSegments,e.heightSegments,e.openEnded,e.thetaStart,e.thetaLength)}},mu=class t extends pu{constructor(e=1,n=1,r=32,i=1,o=!1,s=0,a=Math.PI*2){super(0,e,n,r,i,o,s,a),this.type="ConeGeometry",this.parameters={radius:e,height:n,radialSegments:r,heightSegments:i,openEnded:o,thetaStart:s,thetaLength:a}}static fromJSON(e){return new t(e.radius,e.height,e.radialSegments,e.heightSegments,e.openEnded,e.thetaStart,e.thetaLength)}};var Vn=class{constructor(){this.type="Curve",this.arcLengthDivisions=200,this.needsUpdate=!1,this.cacheArcLengths=null}getPoint(){console.warn("THREE.Curve: .getPoint() not implemented.")}getPointAt(e,n){let r=this.getUtoTmapping(e);return this.getPoint(r,n)}getPoints(e=5){let n=[];for(let r=0;r<=e;r++)n.push(this.getPoint(r/e));return n}getSpacedPoints(e=5){let n=[];for(let r=0;r<=e;r++)n.push(this.getPointAt(r/e));return n}getLength(){let e=this.getLengths();return e[e.length-1]}getLengths(e=this.arcLengthDivisions){if(this.cacheArcLengths&&this.cacheArcLengths.length===e+1&&!this.needsUpdate)return this.cacheArcLengths;this.needsUpdate=!1;let n=[],r,i=this.getPoint(0),o=0;n.push(0);for(let s=1;s<=e;s++)r=this.getPoint(s/e),o+=r.distanceTo(i),n.push(o),i=r;return this.cacheArcLengths=n,n}updateArcLengths(){this.needsUpdate=!0,this.getLengths()}getUtoTmapping(e,n=null){let r=this.getLengths(),i=0,o=r.length,s;n?s=n:s=e*r[o-1];let a=0,l=o-1,u;for(;a<=l;)if(i=Math.floor(a+(l-a)/2),u=r[i]-s,u<0)a=i+1;else if(u>0)l=i-1;else{l=i;break}if(i=l,r[i]===s)return i/(o-1);let c=r[i],h=r[i+1]-c,d=(s-c)/h;return(i+d)/(o-1)}getTangent(e,n){let i=e-1e-4,o=e+1e-4;i<0&&(i=0),o>1&&(o=1);let s=this.getPoint(i),a=this.getPoint(o),l=n||(s.isVector2?new Ie:new k);return l.copy(a).sub(s).normalize(),l}getTangentAt(e,n){let r=this.getUtoTmapping(e);return this.getTangent(r,n)}computeFrenetFrames(e,n=!1){let r=new k,i=[],o=[],s=[],a=new k,l=new Rt;for(let d=0;d<=e;d++){let x=d/e;i[d]=this.getTangentAt(x,new k)}o[0]=new k,s[0]=new k;let u=Number.MAX_VALUE,c=Math.abs(i[0].x),f=Math.abs(i[0].y),h=Math.abs(i[0].z);c<=u&&(u=c,r.set(1,0,0)),f<=u&&(u=f,r.set(0,1,0)),h<=u&&r.set(0,0,1),a.crossVectors(i[0],r).normalize(),o[0].crossVectors(i[0],a),s[0].crossVectors(i[0],o[0]);for(let d=1;d<=e;d++){if(o[d]=o[d-1].clone(),s[d]=s[d-1].clone(),a.crossVectors(i[d-1],i[d]),a.length()>Number.EPSILON){a.normalize();let x=Math.acos(Qe(i[d-1].dot(i[d]),-1,1));o[d].applyMatrix4(l.makeRotationAxis(a,x))}s[d].crossVectors(i[d],o[d])}if(n===!0){let d=Math.acos(Qe(o[0].dot(o[e]),-1,1));d/=e,i[0].dot(a.crossVectors(o[0],o[e]))>0&&(d=-d);for(let x=1;x<=e;x++)o[x].applyMatrix4(l.makeRotationAxis(i[x],d*x)),s[x].crossVectors(i[x],o[x])}return{tangents:i,normals:o,binormals:s}}clone(){return new this.constructor().copy(this)}copy(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}toJSON(){let e={metadata:{version:4.7,type:"Curve",generator:"Curve.toJSON"}};return e.arcLengthDivisions=this.arcLengthDivisions,e.type=this.type,e}fromJSON(e){return this.arcLengthDivisions=e.arcLengthDivisions,this}},Is=class extends Vn{constructor(e=0,n=0,r=1,i=1,o=0,s=Math.PI*2,a=!1,l=0){super(),this.isEllipseCurve=!0,this.type="EllipseCurve",this.aX=e,this.aY=n,this.xRadius=r,this.yRadius=i,this.aStartAngle=o,this.aEndAngle=s,this.aClockwise=a,this.aRotation=l}getPoint(e,n=new Ie){let r=n,i=Math.PI*2,o=this.aEndAngle-this.aStartAngle,s=Math.abs(o)<Number.EPSILON;for(;o<0;)o+=i;for(;o>i;)o-=i;o<Number.EPSILON&&(s?o=0:o=i),this.aClockwise===!0&&!s&&(o===i?o=-i:o=o-i);let a=this.aStartAngle+e*o,l=this.aX+this.xRadius*Math.cos(a),u=this.aY+this.yRadius*Math.sin(a);if(this.aRotation!==0){let c=Math.cos(this.aRotation),f=Math.sin(this.aRotation),h=l-this.aX,d=u-this.aY;l=h*c-d*f+this.aX,u=h*f+d*c+this.aY}return r.set(l,u)}copy(e){return super.copy(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}toJSON(){let e=super.toJSON();return e.aX=this.aX,e.aY=this.aY,e.xRadius=this.xRadius,e.yRadius=this.yRadius,e.aStartAngle=this.aStartAngle,e.aEndAngle=this.aEndAngle,e.aClockwise=this.aClockwise,e.aRotation=this.aRotation,e}fromJSON(e){return super.fromJSON(e),this.aX=e.aX,this.aY=e.aY,this.xRadius=e.xRadius,this.yRadius=e.yRadius,this.aStartAngle=e.aStartAngle,this.aEndAngle=e.aEndAngle,this.aClockwise=e.aClockwise,this.aRotation=e.aRotation,this}},gu=class extends Is{constructor(e,n,r,i,o,s){super(e,n,r,r,i,o,s),this.isArcCurve=!0,this.type="ArcCurve"}};function Dh(){let t=0,e=0,n=0,r=0;function i(o,s,a,l){t=o,e=a,n=-3*o+3*s-2*a-l,r=2*o-2*s+a+l}return{initCatmullRom:function(o,s,a,l,u){i(s,a,u*(a-o),u*(l-s))},initNonuniformCatmullRom:function(o,s,a,l,u,c,f){let h=(s-o)/u-(a-o)/(u+c)+(a-s)/c,d=(a-s)/c-(l-s)/(c+f)+(l-a)/f;h*=c,d*=c,i(s,a,h,d)},calc:function(o){let s=o*o,a=s*o;return t+e*o+n*s+r*a}}}var Qa=new k,qf=new Dh,Xf=new Dh,Yf=new Dh,Po=class extends Vn{constructor(e=[],n=!1,r="centripetal",i=.5){super(),this.isCatmullRomCurve3=!0,this.type="CatmullRomCurve3",this.points=e,this.closed=n,this.curveType=r,this.tension=i}getPoint(e,n=new k){let r=n,i=this.points,o=i.length,s=(o-(this.closed?0:1))*e,a=Math.floor(s),l=s-a;this.closed?a+=a>0?0:(Math.floor(Math.abs(a)/o)+1)*o:l===0&&a===o-1&&(a=o-2,l=1);let u,c;this.closed||a>0?u=i[(a-1)%o]:(Qa.subVectors(i[0],i[1]).add(i[0]),u=Qa);let f=i[a%o],h=i[(a+1)%o];if(this.closed||a+2<o?c=i[(a+2)%o]:(Qa.subVectors(i[o-1],i[o-2]).add(i[o-1]),c=Qa),this.curveType==="centripetal"||this.curveType==="chordal"){let d=this.curveType==="chordal"?.5:.25,x=Math.pow(u.distanceToSquared(f),d),p=Math.pow(f.distanceToSquared(h),d),g=Math.pow(h.distanceToSquared(c),d);p<1e-4&&(p=1),x<1e-4&&(x=p),g<1e-4&&(g=p),qf.initNonuniformCatmullRom(u.x,f.x,h.x,c.x,x,p,g),Xf.initNonuniformCatmullRom(u.y,f.y,h.y,c.y,x,p,g),Yf.initNonuniformCatmullRom(u.z,f.z,h.z,c.z,x,p,g)}else this.curveType==="catmullrom"&&(qf.initCatmullRom(u.x,f.x,h.x,c.x,this.tension),Xf.initCatmullRom(u.y,f.y,h.y,c.y,this.tension),Yf.initCatmullRom(u.z,f.z,h.z,c.z,this.tension));return r.set(qf.calc(l),Xf.calc(l),Yf.calc(l)),r}copy(e){super.copy(e),this.points=[];for(let n=0,r=e.points.length;n<r;n++){let i=e.points[n];this.points.push(i.clone())}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}toJSON(){let e=super.toJSON();e.points=[];for(let n=0,r=this.points.length;n<r;n++){let i=this.points[n];e.points.push(i.toArray())}return e.closed=this.closed,e.curveType=this.curveType,e.tension=this.tension,e}fromJSON(e){super.fromJSON(e),this.points=[];for(let n=0,r=e.points.length;n<r;n++){let i=e.points[n];this.points.push(new k().fromArray(i))}return this.closed=e.closed,this.curveType=e.curveType,this.tension=e.tension,this}};function gm(t,e,n,r,i){let o=(r-e)*.5,s=(i-n)*.5,a=t*t,l=t*a;return(2*n-2*r+o+s)*l+(-3*n+3*r-2*o-s)*a+o*t+n}function jy(t,e){let n=1-t;return n*n*e}function e1(t,e){return 2*(1-t)*t*e}function t1(t,e){return t*t*e}function vs(t,e,n,r){return jy(t,e)+e1(t,n)+t1(t,r)}function n1(t,e){let n=1-t;return n*n*n*e}function r1(t,e){let n=1-t;return 3*n*n*t*e}function i1(t,e){return 3*(1-t)*t*t*e}function o1(t,e){return t*t*t*e}function _s(t,e,n,r,i){return n1(t,e)+r1(t,n)+i1(t,r)+o1(t,i)}var xu=class extends Vn{constructor(e=new Ie,n=new Ie,r=new Ie,i=new Ie){super(),this.isCubicBezierCurve=!0,this.type="CubicBezierCurve",this.v0=e,this.v1=n,this.v2=r,this.v3=i}getPoint(e,n=new Ie){let r=n,i=this.v0,o=this.v1,s=this.v2,a=this.v3;return r.set(_s(e,i.x,o.x,s.x,a.x),_s(e,i.y,o.y,s.y,a.y)),r}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},vu=class extends Vn{constructor(e=new k,n=new k,r=new k,i=new k){super(),this.isCubicBezierCurve3=!0,this.type="CubicBezierCurve3",this.v0=e,this.v1=n,this.v2=r,this.v3=i}getPoint(e,n=new k){let r=n,i=this.v0,o=this.v1,s=this.v2,a=this.v3;return r.set(_s(e,i.x,o.x,s.x,a.x),_s(e,i.y,o.y,s.y,a.y),_s(e,i.z,o.z,s.z,a.z)),r}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this.v3.copy(e.v3),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e.v3=this.v3.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this.v3.fromArray(e.v3),this}},_u=class extends Vn{constructor(e=new Ie,n=new Ie){super(),this.isLineCurve=!0,this.type="LineCurve",this.v1=e,this.v2=n}getPoint(e,n=new Ie){let r=n;return e===1?r.copy(this.v2):(r.copy(this.v2).sub(this.v1),r.multiplyScalar(e).add(this.v1)),r}getPointAt(e,n){return this.getPoint(e,n)}getTangent(e,n=new Ie){return n.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,n){return this.getTangent(e,n)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},yu=class extends Vn{constructor(e=new k,n=new k){super(),this.isLineCurve3=!0,this.type="LineCurve3",this.v1=e,this.v2=n}getPoint(e,n=new k){let r=n;return e===1?r.copy(this.v2):(r.copy(this.v2).sub(this.v1),r.multiplyScalar(e).add(this.v1)),r}getPointAt(e,n){return this.getPoint(e,n)}getTangent(e,n=new k){return n.subVectors(this.v2,this.v1).normalize()}getTangentAt(e,n){return this.getTangent(e,n)}copy(e){return super.copy(e),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Mu=class extends Vn{constructor(e=new Ie,n=new Ie,r=new Ie){super(),this.isQuadraticBezierCurve=!0,this.type="QuadraticBezierCurve",this.v0=e,this.v1=n,this.v2=r}getPoint(e,n=new Ie){let r=n,i=this.v0,o=this.v1,s=this.v2;return r.set(vs(e,i.x,o.x,s.x),vs(e,i.y,o.y,s.y)),r}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Ns=class extends Vn{constructor(e=new k,n=new k,r=new k){super(),this.isQuadraticBezierCurve3=!0,this.type="QuadraticBezierCurve3",this.v0=e,this.v1=n,this.v2=r}getPoint(e,n=new k){let r=n,i=this.v0,o=this.v1,s=this.v2;return r.set(vs(e,i.x,o.x,s.x),vs(e,i.y,o.y,s.y),vs(e,i.z,o.z,s.z)),r}copy(e){return super.copy(e),this.v0.copy(e.v0),this.v1.copy(e.v1),this.v2.copy(e.v2),this}toJSON(){let e=super.toJSON();return e.v0=this.v0.toArray(),e.v1=this.v1.toArray(),e.v2=this.v2.toArray(),e}fromJSON(e){return super.fromJSON(e),this.v0.fromArray(e.v0),this.v1.fromArray(e.v1),this.v2.fromArray(e.v2),this}},Su=class extends Vn{constructor(e=[]){super(),this.isSplineCurve=!0,this.type="SplineCurve",this.points=e}getPoint(e,n=new Ie){let r=n,i=this.points,o=(i.length-1)*e,s=Math.floor(o),a=o-s,l=i[s===0?s:s-1],u=i[s],c=i[s>i.length-2?i.length-1:s+1],f=i[s>i.length-3?i.length-1:s+2];return r.set(gm(a,l.x,u.x,c.x,f.x),gm(a,l.y,u.y,c.y,f.y)),r}copy(e){super.copy(e),this.points=[];for(let n=0,r=e.points.length;n<r;n++){let i=e.points[n];this.points.push(i.clone())}return this}toJSON(){let e=super.toJSON();e.points=[];for(let n=0,r=this.points.length;n<r;n++){let i=this.points[n];e.points.push(i.toArray())}return e}fromJSON(e){super.fromJSON(e),this.points=[];for(let n=0,r=e.points.length;n<r;n++){let i=e.points[n];this.points.push(new Ie().fromArray(i))}return this}},s1=Object.freeze({__proto__:null,ArcCurve:gu,CatmullRomCurve3:Po,CubicBezierCurve:xu,CubicBezierCurve3:vu,EllipseCurve:Is,LineCurve:_u,LineCurve3:yu,QuadraticBezierCurve:Mu,QuadraticBezierCurve3:Ns,SplineCurve:Su});var Ri=class t extends cn{constructor(e=1,n=1,r=1,i=1){super(),this.type="PlaneGeometry",this.parameters={width:e,height:n,widthSegments:r,heightSegments:i};let o=e/2,s=n/2,a=Math.floor(r),l=Math.floor(i),u=a+1,c=l+1,f=e/a,h=n/l,d=[],x=[],p=[],g=[];for(let m=0;m<c;m++){let b=m*h-s;for(let v=0;v<u;v++){let _=v*f-o;x.push(_,-b,0),p.push(0,0,1),g.push(v/a),g.push(1-m/l)}}for(let m=0;m<l;m++)for(let b=0;b<a;b++){let v=b+u*m,_=b+u*(m+1),M=b+1+u*(m+1),y=b+1+u*m;d.push(v,_,y),d.push(_,M,y)}this.setIndex(d),this.setAttribute("position",new qt(x,3)),this.setAttribute("normal",new qt(p,3)),this.setAttribute("uv",new qt(g,2))}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}static fromJSON(e){return new t(e.width,e.height,e.widthSegments,e.heightSegments)}};var Ls=class t extends cn{constructor(e=new Ns(new k(-1,-1,0),new k(-1,1,0),new k(1,1,0)),n=64,r=1,i=8,o=!1){super(),this.type="TubeGeometry",this.parameters={path:e,tubularSegments:n,radius:r,radialSegments:i,closed:o};let s=e.computeFrenetFrames(n,o);this.tangents=s.tangents,this.normals=s.normals,this.binormals=s.binormals;let a=new k,l=new k,u=new Ie,c=new k,f=[],h=[],d=[],x=[];p(),this.setIndex(x),this.setAttribute("position",new qt(f,3)),this.setAttribute("normal",new qt(h,3)),this.setAttribute("uv",new qt(d,2));function p(){for(let v=0;v<n;v++)g(v);g(o===!1?n:0),b(),m()}function g(v){c=e.getPointAt(v/n,c);let _=s.normals[v],M=s.binormals[v];for(let y=0;y<=i;y++){let E=y/i*Math.PI*2,D=Math.sin(E),S=-Math.cos(E);l.x=S*_.x+D*M.x,l.y=S*_.y+D*M.y,l.z=S*_.z+D*M.z,l.normalize(),h.push(l.x,l.y,l.z),a.x=c.x+r*l.x,a.y=c.y+r*l.y,a.z=c.z+r*l.z,f.push(a.x,a.y,a.z)}}function m(){for(let v=1;v<=n;v++)for(let _=1;_<=i;_++){let M=(i+1)*(v-1)+(_-1),y=(i+1)*v+(_-1),E=(i+1)*v+_,D=(i+1)*(v-1)+_;x.push(M,y,D),x.push(y,E,D)}}function b(){for(let v=0;v<=n;v++)for(let _=0;_<=i;_++)u.x=v/n,u.y=_/i,d.push(u.x,u.y)}}copy(e){return super.copy(e),this.parameters=Object.assign({},e.parameters),this}toJSON(){let e=super.toJSON();return e.path=this.parameters.path.toJSON(),e}static fromJSON(e){return new t(new s1[e.path.type]().fromJSON(e.path),e.tubularSegments,e.radius,e.radialSegments,e.closed)}};var Bs=class extends Cr{constructor(e){super(),this.isMeshStandardMaterial=!0,this.type="MeshStandardMaterial",this.defines={STANDARD:""},this.color=new it(16777215),this.roughness=1,this.metalness=0,this.map=null,this.lightMap=null,this.lightMapIntensity=1,this.aoMap=null,this.aoMapIntensity=1,this.emissive=new it(0),this.emissiveIntensity=1,this.emissiveMap=null,this.bumpMap=null,this.bumpScale=1,this.normalMap=null,this.normalMapType=_h,this.normalScale=new Ie(1,1),this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.roughnessMap=null,this.metalnessMap=null,this.alphaMap=null,this.envMap=null,this.envMapRotation=new Kn,this.envMapIntensity=1,this.wireframe=!1,this.wireframeLinewidth=1,this.wireframeLinecap="round",this.wireframeLinejoin="round",this.flatShading=!1,this.fog=!0,this.setValues(e)}copy(e){return super.copy(e),this.defines={STANDARD:""},this.color.copy(e.color),this.roughness=e.roughness,this.metalness=e.metalness,this.map=e.map,this.lightMap=e.lightMap,this.lightMapIntensity=e.lightMapIntensity,this.aoMap=e.aoMap,this.aoMapIntensity=e.aoMapIntensity,this.emissive.copy(e.emissive),this.emissiveMap=e.emissiveMap,this.emissiveIntensity=e.emissiveIntensity,this.bumpMap=e.bumpMap,this.bumpScale=e.bumpScale,this.normalMap=e.normalMap,this.normalMapType=e.normalMapType,this.normalScale.copy(e.normalScale),this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.roughnessMap=e.roughnessMap,this.metalnessMap=e.metalnessMap,this.alphaMap=e.alphaMap,this.envMap=e.envMap,this.envMapRotation.copy(e.envMapRotation),this.envMapIntensity=e.envMapIntensity,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this.wireframeLinecap=e.wireframeLinecap,this.wireframeLinejoin=e.wireframeLinejoin,this.flatShading=e.flatShading,this.fog=e.fog,this}};var wu=class extends Cr{constructor(e){super(),this.isMeshDepthMaterial=!0,this.type="MeshDepthMaterial",this.depthPacking=Km,this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.wireframe=!1,this.wireframeLinewidth=1,this.setValues(e)}copy(e){return super.copy(e),this.depthPacking=e.depthPacking,this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this.wireframe=e.wireframe,this.wireframeLinewidth=e.wireframeLinewidth,this}},bu=class extends Cr{constructor(e){super(),this.isMeshDistanceMaterial=!0,this.type="MeshDistanceMaterial",this.map=null,this.alphaMap=null,this.displacementMap=null,this.displacementScale=1,this.displacementBias=0,this.setValues(e)}copy(e){return super.copy(e),this.map=e.map,this.alphaMap=e.alphaMap,this.displacementMap=e.displacementMap,this.displacementScale=e.displacementScale,this.displacementBias=e.displacementBias,this}};var Us=class extends Ro{constructor(e){super(),this.isLineDashedMaterial=!0,this.type="LineDashedMaterial",this.scale=1,this.dashSize=3,this.gapSize=1,this.setValues(e)}copy(e){return super.copy(e),this.scale=e.scale,this.dashSize=e.dashSize,this.gapSize=e.gapSize,this}};function ja(t,e){return!t||t.constructor===e?t:typeof e.BYTES_PER_ELEMENT=="number"?new e(t):Array.prototype.slice.call(t)}function a1(t){return ArrayBuffer.isView(t)&&!(t instanceof DataView)}var Fi=class{constructor(e,n,r,i){this.parameterPositions=e,this._cachedIndex=0,this.resultBuffer=i!==void 0?i:new n.constructor(r),this.sampleValues=n,this.valueSize=r,this.settings=null,this.DefaultSettings_={}}evaluate(e){let n=this.parameterPositions,r=this._cachedIndex,i=n[r],o=n[r-1];e:{t:{let s;n:{r:if(!(e<i)){for(let a=r+2;;){if(i===void 0){if(e<o)break r;return r=n.length,this._cachedIndex=r,this.copySampleValue_(r-1)}if(r===a)break;if(o=i,i=n[++r],e<i)break t}s=n.length;break n}if(!(e>=o)){let a=n[1];e<a&&(r=2,o=a);for(let l=r-2;;){if(o===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(r===l)break;if(i=o,o=n[--r-1],e>=o)break t}s=r,r=0;break n}break e}for(;r<s;){let a=r+s>>>1;e<n[a]?s=a:r=a+1}if(i=n[r],o=n[r-1],o===void 0)return this._cachedIndex=0,this.copySampleValue_(0);if(i===void 0)return r=n.length,this._cachedIndex=r,this.copySampleValue_(r-1)}this._cachedIndex=r,this.intervalChanged_(r,o,i)}return this.interpolate_(r,o,e,i)}getSettings_(){return this.settings||this.DefaultSettings_}copySampleValue_(e){let n=this.resultBuffer,r=this.sampleValues,i=this.valueSize,o=e*i;for(let s=0;s!==i;++s)n[s]=r[o+s];return n}interpolate_(){throw new Error("call to abstract method")}intervalChanged_(){}},Eu=class extends Fi{constructor(e,n,r,i){super(e,n,r,i),this._weightPrev=-0,this._offsetPrev=-0,this._weightNext=-0,this._offsetNext=-0,this.DefaultSettings_={endingStart:Jf,endingEnd:Jf}}intervalChanged_(e,n,r){let i=this.parameterPositions,o=e-2,s=e+1,a=i[o],l=i[s];if(a===void 0)switch(this.getSettings_().endingStart){case Kf:o=e,a=2*n-r;break;case Qf:o=i.length-2,a=n+i[o]-i[o+1];break;default:o=e,a=r}if(l===void 0)switch(this.getSettings_().endingEnd){case Kf:s=e,l=2*r-n;break;case Qf:s=1,l=r+i[1]-i[0];break;default:s=e-1,l=n}let u=(r-n)*.5,c=this.valueSize;this._weightPrev=u/(n-a),this._weightNext=u/(l-r),this._offsetPrev=o*c,this._offsetNext=s*c}interpolate_(e,n,r,i){let o=this.resultBuffer,s=this.sampleValues,a=this.valueSize,l=e*a,u=l-a,c=this._offsetPrev,f=this._offsetNext,h=this._weightPrev,d=this._weightNext,x=(r-n)/(i-n),p=x*x,g=p*x,m=-h*g+2*h*p-h*x,b=(1+h)*g+(-1.5-2*h)*p+(-.5+h)*x+1,v=(-1-d)*g+(1.5+d)*p+.5*x,_=d*g-d*p;for(let M=0;M!==a;++M)o[M]=m*s[c+M]+b*s[u+M]+v*s[l+M]+_*s[f+M];return o}},Du=class extends Fi{constructor(e,n,r,i){super(e,n,r,i)}interpolate_(e,n,r,i){let o=this.resultBuffer,s=this.sampleValues,a=this.valueSize,l=e*a,u=l-a,c=(r-n)/(i-n),f=1-c;for(let h=0;h!==a;++h)o[h]=s[u+h]*f+s[l+h]*c;return o}},Au=class extends Fi{constructor(e,n,r,i){super(e,n,r,i)}interpolate_(e){return this.copySampleValue_(e-1)}},Rn=class{constructor(e,n,r,i){if(e===void 0)throw new Error("THREE.KeyframeTrack: track name is undefined");if(n===void 0||n.length===0)throw new Error("THREE.KeyframeTrack: no keyframes in track named "+e);this.name=e,this.times=ja(n,this.TimeBufferType),this.values=ja(r,this.ValueBufferType),this.setInterpolation(i||this.DefaultInterpolation)}static toJSON(e){let n=e.constructor,r;if(n.toJSON!==this.toJSON)r=n.toJSON(e);else{r={name:e.name,times:ja(e.times,Array),values:ja(e.values,Array)};let i=e.getInterpolation();i!==e.DefaultInterpolation&&(r.interpolation=i)}return r.type=e.ValueTypeName,r}InterpolantFactoryMethodDiscrete(e){return new Au(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodLinear(e){return new Du(this.times,this.values,this.getValueSize(),e)}InterpolantFactoryMethodSmooth(e){return new Eu(this.times,this.values,this.getValueSize(),e)}setInterpolation(e){let n;switch(e){case ys:n=this.InterpolantFactoryMethodDiscrete;break;case su:n=this.InterpolantFactoryMethodLinear;break;case tu:n=this.InterpolantFactoryMethodSmooth;break}if(n===void 0){let r="unsupported interpolation for "+this.ValueTypeName+" keyframe track named "+this.name;if(this.createInterpolant===void 0)if(e!==this.DefaultInterpolation)this.setInterpolation(this.DefaultInterpolation);else throw new Error(r);return console.warn("THREE.KeyframeTrack:",r),this}return this.createInterpolant=n,this}getInterpolation(){switch(this.createInterpolant){case this.InterpolantFactoryMethodDiscrete:return ys;case this.InterpolantFactoryMethodLinear:return su;case this.InterpolantFactoryMethodSmooth:return tu}}getValueSize(){return this.values.length/this.times.length}shift(e){if(e!==0){let n=this.times;for(let r=0,i=n.length;r!==i;++r)n[r]+=e}return this}scale(e){if(e!==1){let n=this.times;for(let r=0,i=n.length;r!==i;++r)n[r]*=e}return this}trim(e,n){let r=this.times,i=r.length,o=0,s=i-1;for(;o!==i&&r[o]<e;)++o;for(;s!==-1&&r[s]>n;)--s;if(++s,o!==0||s!==i){o>=s&&(s=Math.max(s,1),o=s-1);let a=this.getValueSize();this.times=r.slice(o,s),this.values=this.values.slice(o*a,s*a)}return this}validate(){let e=!0,n=this.getValueSize();n-Math.floor(n)!==0&&(console.error("THREE.KeyframeTrack: Invalid value size in track.",this),e=!1);let r=this.times,i=this.values,o=r.length;o===0&&(console.error("THREE.KeyframeTrack: Track is empty.",this),e=!1);let s=null;for(let a=0;a!==o;a++){let l=r[a];if(typeof l=="number"&&isNaN(l)){console.error("THREE.KeyframeTrack: Time is not a valid number.",this,a,l),e=!1;break}if(s!==null&&s>l){console.error("THREE.KeyframeTrack: Out of order keys.",this,a,l,s),e=!1;break}s=l}if(i!==void 0&&a1(i))for(let a=0,l=i.length;a!==l;++a){let u=i[a];if(isNaN(u)){console.error("THREE.KeyframeTrack: Value is not a valid number.",this,a,u),e=!1;break}}return e}optimize(){let e=this.times.slice(),n=this.values.slice(),r=this.getValueSize(),i=this.getInterpolation()===tu,o=e.length-1,s=1;for(let a=1;a<o;++a){let l=!1,u=e[a],c=e[a+1];if(u!==c&&(a!==1||u!==e[0]))if(i)l=!0;else{let f=a*r,h=f-r,d=f+r;for(let x=0;x!==r;++x){let p=n[f+x];if(p!==n[h+x]||p!==n[d+x]){l=!0;break}}}if(l){if(a!==s){e[s]=e[a];let f=a*r,h=s*r;for(let d=0;d!==r;++d)n[h+d]=n[f+d]}++s}}if(o>0){e[s]=e[o];for(let a=o*r,l=s*r,u=0;u!==r;++u)n[l+u]=n[a+u];++s}return s!==e.length?(this.times=e.slice(0,s),this.values=n.slice(0,s*r)):(this.times=e,this.values=n),this}clone(){let e=this.times.slice(),n=this.values.slice(),r=this.constructor,i=new r(this.name,e,n);return i.createInterpolant=this.createInterpolant,i}};Rn.prototype.ValueTypeName="";Rn.prototype.TimeBufferType=Float32Array;Rn.prototype.ValueBufferType=Float32Array;Rn.prototype.DefaultInterpolation=su;var Kr=class extends Rn{constructor(e,n,r){super(e,n,r)}};Kr.prototype.ValueTypeName="bool";Kr.prototype.ValueBufferType=Array;Kr.prototype.DefaultInterpolation=ys;Kr.prototype.InterpolantFactoryMethodLinear=void 0;Kr.prototype.InterpolantFactoryMethodSmooth=void 0;var Cu=class extends Rn{constructor(e,n,r,i){super(e,n,r,i)}};Cu.prototype.ValueTypeName="color";var Tu=class extends Rn{constructor(e,n,r,i){super(e,n,r,i)}};Tu.prototype.ValueTypeName="number";var Ru=class extends Fi{constructor(e,n,r,i){super(e,n,r,i)}interpolate_(e,n,r,i){let o=this.resultBuffer,s=this.sampleValues,a=this.valueSize,l=(r-n)/(i-n),u=e*a;for(let c=u+a;u!==c;u+=4)kn.slerpFlat(o,0,s,u-a,s,u,l);return o}},Os=class extends Rn{constructor(e,n,r,i){super(e,n,r,i)}InterpolantFactoryMethodLinear(e){return new Ru(this.times,this.values,this.getValueSize(),e)}};Os.prototype.ValueTypeName="quaternion";Os.prototype.InterpolantFactoryMethodSmooth=void 0;var Qr=class extends Rn{constructor(e,n,r){super(e,n,r)}};Qr.prototype.ValueTypeName="string";Qr.prototype.ValueBufferType=Array;Qr.prototype.DefaultInterpolation=ys;Qr.prototype.InterpolantFactoryMethodLinear=void 0;Qr.prototype.InterpolantFactoryMethodSmooth=void 0;var Fu=class extends Rn{constructor(e,n,r,i){super(e,n,r,i)}};Fu.prototype.ValueTypeName="vector";var Pu=class{constructor(e,n,r){let i=this,o=!1,s=0,a=0,l,u=[];this.onStart=void 0,this.onLoad=e,this.onProgress=n,this.onError=r,this.abortController=new AbortController,this.itemStart=function(c){a++,o===!1&&i.onStart!==void 0&&i.onStart(c,s,a),o=!0},this.itemEnd=function(c){s++,i.onProgress!==void 0&&i.onProgress(c,s,a),s===a&&(o=!1,i.onLoad!==void 0&&i.onLoad())},this.itemError=function(c){i.onError!==void 0&&i.onError(c)},this.resolveURL=function(c){return l?l(c):c},this.setURLModifier=function(c){return l=c,this},this.addHandler=function(c,f){return u.push(c,f),this},this.removeHandler=function(c){let f=u.indexOf(c);return f!==-1&&u.splice(f,2),this},this.getHandler=function(c){for(let f=0,h=u.length;f<h;f+=2){let d=u[f],x=u[f+1];if(d.global&&(d.lastIndex=0),d.test(c))return x}return null},this.abort=function(){return this.abortController.abort(),this.abortController=new AbortController,this}}},fg=new Pu,Iu=class{constructor(e){this.manager=e!==void 0?e:fg,this.crossOrigin="anonymous",this.withCredentials=!1,this.path="",this.resourcePath="",this.requestHeader={}}load(){}loadAsync(e,n){let r=this;return new Promise(function(i,o){r.load(e,i,n,o)})}parse(){}setCrossOrigin(e){return this.crossOrigin=e,this}setWithCredentials(e){return this.withCredentials=e,this}setPath(e){return this.path=e,this}setResourcePath(e){return this.resourcePath=e,this}setRequestHeader(e){return this.requestHeader=e,this}abort(){return this}};Iu.DEFAULT_MATERIAL_NAME="__DEFAULT";var zs=class extends Xt{constructor(e,n=1){super(),this.isLight=!0,this.type="Light",this.color=new it(e),this.intensity=n}dispose(){}copy(e,n){return super.copy(e,n),this.color.copy(e.color),this.intensity=e.intensity,this}toJSON(e){let n=super.toJSON(e);return n.object.color=this.color.getHex(),n.object.intensity=this.intensity,this.groundColor!==void 0&&(n.object.groundColor=this.groundColor.getHex()),this.distance!==void 0&&(n.object.distance=this.distance),this.angle!==void 0&&(n.object.angle=this.angle),this.decay!==void 0&&(n.object.decay=this.decay),this.penumbra!==void 0&&(n.object.penumbra=this.penumbra),this.shadow!==void 0&&(n.object.shadow=this.shadow.toJSON()),this.target!==void 0&&(n.object.target=this.target.uuid),n}},ks=class extends zs{constructor(e,n,r){super(e,r),this.isHemisphereLight=!0,this.type="HemisphereLight",this.position.copy(Xt.DEFAULT_UP),this.updateMatrix(),this.groundColor=new it(n)}copy(e,n){return super.copy(e,n),this.groundColor.copy(e.groundColor),this}},Zf=new Rt,xm=new k,vm=new k,th=class{constructor(e){this.camera=e,this.intensity=1,this.bias=0,this.normalBias=0,this.radius=1,this.blurSamples=8,this.mapSize=new Ie(512,512),this.mapType=er,this.map=null,this.mapPass=null,this.matrix=new Rt,this.autoUpdate=!0,this.needsUpdate=!1,this._frustum=new To,this._frameExtents=new Ie(1,1),this._viewportCount=1,this._viewports=[new Ft(0,0,1,1)]}getViewportCount(){return this._viewportCount}getFrustum(){return this._frustum}updateMatrices(e){let n=this.camera,r=this.matrix;xm.setFromMatrixPosition(e.matrixWorld),n.position.copy(xm),vm.setFromMatrixPosition(e.target.matrixWorld),n.lookAt(vm),n.updateMatrixWorld(),Zf.multiplyMatrices(n.projectionMatrix,n.matrixWorldInverse),this._frustum.setFromProjectionMatrix(Zf,n.coordinateSystem,n.reversedDepth),n.reversedDepth?r.set(.5,0,0,.5,0,.5,0,.5,0,0,1,0,0,0,0,1):r.set(.5,0,0,.5,0,.5,0,.5,0,0,.5,.5,0,0,0,1),r.multiply(Zf)}getViewport(e){return this._viewports[e]}getFrameExtents(){return this._frameExtents}dispose(){this.map&&this.map.dispose(),this.mapPass&&this.mapPass.dispose()}copy(e){return this.camera=e.camera.clone(),this.intensity=e.intensity,this.bias=e.bias,this.radius=e.radius,this.autoUpdate=e.autoUpdate,this.needsUpdate=e.needsUpdate,this.normalBias=e.normalBias,this.blurSamples=e.blurSamples,this.mapSize.copy(e.mapSize),this}clone(){return new this.constructor().copy(this)}toJSON(){let e={};return this.intensity!==1&&(e.intensity=this.intensity),this.bias!==0&&(e.bias=this.bias),this.normalBias!==0&&(e.normalBias=this.normalBias),this.radius!==1&&(e.radius=this.radius),(this.mapSize.x!==512||this.mapSize.y!==512)&&(e.mapSize=this.mapSize.toArray()),e.camera=this.camera.toJSON(!1).object,delete e.camera.matrix,e}};var Vs=class extends Cs{constructor(e=-1,n=1,r=1,i=-1,o=.1,s=2e3){super(),this.isOrthographicCamera=!0,this.type="OrthographicCamera",this.zoom=1,this.view=null,this.left=e,this.right=n,this.top=r,this.bottom=i,this.near=o,this.far=s,this.updateProjectionMatrix()}copy(e,n){return super.copy(e,n),this.left=e.left,this.right=e.right,this.top=e.top,this.bottom=e.bottom,this.near=e.near,this.far=e.far,this.zoom=e.zoom,this.view=e.view===null?null:Object.assign({},e.view),this}setViewOffset(e,n,r,i,o,s){this.view===null&&(this.view={enabled:!0,fullWidth:1,fullHeight:1,offsetX:0,offsetY:0,width:1,height:1}),this.view.enabled=!0,this.view.fullWidth=e,this.view.fullHeight=n,this.view.offsetX=r,this.view.offsetY=i,this.view.width=o,this.view.height=s,this.updateProjectionMatrix()}clearViewOffset(){this.view!==null&&(this.view.enabled=!1),this.updateProjectionMatrix()}updateProjectionMatrix(){let e=(this.right-this.left)/(2*this.zoom),n=(this.top-this.bottom)/(2*this.zoom),r=(this.right+this.left)/2,i=(this.top+this.bottom)/2,o=r-e,s=r+e,a=i+n,l=i-n;if(this.view!==null&&this.view.enabled){let u=(this.right-this.left)/this.view.fullWidth/this.zoom,c=(this.top-this.bottom)/this.view.fullHeight/this.zoom;o+=u*this.view.offsetX,s=o+u*this.view.width,a-=c*this.view.offsetY,l=a-c*this.view.height}this.projectionMatrix.makeOrthographic(o,s,a,l,this.near,this.far,this.coordinateSystem,this.reversedDepth),this.projectionMatrixInverse.copy(this.projectionMatrix).invert()}toJSON(e){let n=super.toJSON(e);return n.object.zoom=this.zoom,n.object.left=this.left,n.object.right=this.right,n.object.top=this.top,n.object.bottom=this.bottom,n.object.near=this.near,n.object.far=this.far,this.view!==null&&(n.object.view=Object.assign({},this.view)),n}},nh=class extends th{constructor(){super(new Vs(-5,5,5,-5,.5,500)),this.isDirectionalLightShadow=!0}},Hs=class extends zs{constructor(e,n){super(e,n),this.isDirectionalLight=!0,this.type="DirectionalLight",this.position.copy(Xt.DEFAULT_UP),this.updateMatrix(),this.target=new Xt,this.shadow=new nh}dispose(){this.shadow.dispose()}copy(e){return super.copy(e),this.target=e.target.clone(),this.shadow=e.shadow.clone(),this}};var Nu=class extends tn{constructor(e=[]){super(),this.isArrayCamera=!0,this.isMultiViewCamera=!1,this.cameras=e}};var Ah="\\[\\]\\.:\\/",u1=new RegExp("["+Ah+"]","g"),Ch="[^"+Ah+"]",l1="[^"+Ah.replace("\\.","")+"]",c1=/((?:WC+[\/:])*)/.source.replace("WC",Ch),f1=/(WCOD+)?/.source.replace("WCOD",l1),h1=/(?:\.(WC+)(?:\[(.+)\])?)?/.source.replace("WC",Ch),d1=/\.(WC+)(?:\[(.+)\])?/.source.replace("WC",Ch),p1=new RegExp("^"+c1+f1+h1+d1+"$"),m1=["material","materials","bones","map"],rh=class{constructor(e,n,r){let i=r||wt.parseTrackName(n);this._targetGroup=e,this._bindings=e.subscribe_(n,i)}getValue(e,n){this.bind();let r=this._targetGroup.nCachedObjects_,i=this._bindings[r];i!==void 0&&i.getValue(e,n)}setValue(e,n){let r=this._bindings;for(let i=this._targetGroup.nCachedObjects_,o=r.length;i!==o;++i)r[i].setValue(e,n)}bind(){let e=this._bindings;for(let n=this._targetGroup.nCachedObjects_,r=e.length;n!==r;++n)e[n].bind()}unbind(){let e=this._bindings;for(let n=this._targetGroup.nCachedObjects_,r=e.length;n!==r;++n)e[n].unbind()}},wt=class t{constructor(e,n,r){this.path=n,this.parsedPath=r||t.parseTrackName(n),this.node=t.findNode(e,this.parsedPath.nodeName),this.rootNode=e,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}static create(e,n,r){return e&&e.isAnimationObjectGroup?new t.Composite(e,n,r):new t(e,n,r)}static sanitizeNodeName(e){return e.replace(/\s/g,"_").replace(u1,"")}static parseTrackName(e){let n=p1.exec(e);if(n===null)throw new Error("PropertyBinding: Cannot parse trackName: "+e);let r={nodeName:n[2],objectName:n[3],objectIndex:n[4],propertyName:n[5],propertyIndex:n[6]},i=r.nodeName&&r.nodeName.lastIndexOf(".");if(i!==void 0&&i!==-1){let o=r.nodeName.substring(i+1);m1.indexOf(o)!==-1&&(r.nodeName=r.nodeName.substring(0,i),r.objectName=o)}if(r.propertyName===null||r.propertyName.length===0)throw new Error("PropertyBinding: can not parse propertyName from trackName: "+e);return r}static findNode(e,n){if(n===void 0||n===""||n==="."||n===-1||n===e.name||n===e.uuid)return e;if(e.skeleton){let r=e.skeleton.getBoneByName(n);if(r!==void 0)return r}if(e.children){let r=function(o){for(let s=0;s<o.length;s++){let a=o[s];if(a.name===n||a.uuid===n)return a;let l=r(a.children);if(l)return l}return null},i=r(e.children);if(i)return i}return null}_getValue_unavailable(){}_setValue_unavailable(){}_getValue_direct(e,n){e[n]=this.targetObject[this.propertyName]}_getValue_array(e,n){let r=this.resolvedProperty;for(let i=0,o=r.length;i!==o;++i)e[n++]=r[i]}_getValue_arrayElement(e,n){e[n]=this.resolvedProperty[this.propertyIndex]}_getValue_toArray(e,n){this.resolvedProperty.toArray(e,n)}_setValue_direct(e,n){this.targetObject[this.propertyName]=e[n]}_setValue_direct_setNeedsUpdate(e,n){this.targetObject[this.propertyName]=e[n],this.targetObject.needsUpdate=!0}_setValue_direct_setMatrixWorldNeedsUpdate(e,n){this.targetObject[this.propertyName]=e[n],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_array(e,n){let r=this.resolvedProperty;for(let i=0,o=r.length;i!==o;++i)r[i]=e[n++]}_setValue_array_setNeedsUpdate(e,n){let r=this.resolvedProperty;for(let i=0,o=r.length;i!==o;++i)r[i]=e[n++];this.targetObject.needsUpdate=!0}_setValue_array_setMatrixWorldNeedsUpdate(e,n){let r=this.resolvedProperty;for(let i=0,o=r.length;i!==o;++i)r[i]=e[n++];this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_arrayElement(e,n){this.resolvedProperty[this.propertyIndex]=e[n]}_setValue_arrayElement_setNeedsUpdate(e,n){this.resolvedProperty[this.propertyIndex]=e[n],this.targetObject.needsUpdate=!0}_setValue_arrayElement_setMatrixWorldNeedsUpdate(e,n){this.resolvedProperty[this.propertyIndex]=e[n],this.targetObject.matrixWorldNeedsUpdate=!0}_setValue_fromArray(e,n){this.resolvedProperty.fromArray(e,n)}_setValue_fromArray_setNeedsUpdate(e,n){this.resolvedProperty.fromArray(e,n),this.targetObject.needsUpdate=!0}_setValue_fromArray_setMatrixWorldNeedsUpdate(e,n){this.resolvedProperty.fromArray(e,n),this.targetObject.matrixWorldNeedsUpdate=!0}_getValue_unbound(e,n){this.bind(),this.getValue(e,n)}_setValue_unbound(e,n){this.bind(),this.setValue(e,n)}bind(){let e=this.node,n=this.parsedPath,r=n.objectName,i=n.propertyName,o=n.propertyIndex;if(e||(e=t.findNode(this.rootNode,n.nodeName),this.node=e),this.getValue=this._getValue_unavailable,this.setValue=this._setValue_unavailable,!e){console.warn("THREE.PropertyBinding: No target node found for track: "+this.path+".");return}if(r){let u=n.objectIndex;switch(r){case"materials":if(!e.material){console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.",this);return}if(!e.material.materials){console.error("THREE.PropertyBinding: Can not bind to material.materials as node.material does not have a materials array.",this);return}e=e.material.materials;break;case"bones":if(!e.skeleton){console.error("THREE.PropertyBinding: Can not bind to bones as node does not have a skeleton.",this);return}e=e.skeleton.bones;for(let c=0;c<e.length;c++)if(e[c].name===u){u=c;break}break;case"map":if("map"in e){e=e.map;break}if(!e.material){console.error("THREE.PropertyBinding: Can not bind to material as node does not have a material.",this);return}if(!e.material.map){console.error("THREE.PropertyBinding: Can not bind to material.map as node.material does not have a map.",this);return}e=e.material.map;break;default:if(e[r]===void 0){console.error("THREE.PropertyBinding: Can not bind to objectName of node undefined.",this);return}e=e[r]}if(u!==void 0){if(e[u]===void 0){console.error("THREE.PropertyBinding: Trying to bind to objectIndex of objectName, but is undefined.",this,e);return}e=e[u]}}let s=e[i];if(s===void 0){let u=n.nodeName;console.error("THREE.PropertyBinding: Trying to update property for track: "+u+"."+i+" but it wasn't found.",e);return}let a=this.Versioning.None;this.targetObject=e,e.isMaterial===!0?a=this.Versioning.NeedsUpdate:e.isObject3D===!0&&(a=this.Versioning.MatrixWorldNeedsUpdate);let l=this.BindingType.Direct;if(o!==void 0){if(i==="morphTargetInfluences"){if(!e.geometry){console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.",this);return}if(!e.geometry.morphAttributes){console.error("THREE.PropertyBinding: Can not bind to morphTargetInfluences because node does not have a geometry.morphAttributes.",this);return}e.morphTargetDictionary[o]!==void 0&&(o=e.morphTargetDictionary[o])}l=this.BindingType.ArrayElement,this.resolvedProperty=s,this.propertyIndex=o}else s.fromArray!==void 0&&s.toArray!==void 0?(l=this.BindingType.HasFromToArray,this.resolvedProperty=s):Array.isArray(s)?(l=this.BindingType.EntireArray,this.resolvedProperty=s):this.propertyName=i;this.getValue=this.GetterByBindingType[l],this.setValue=this.SetterByBindingTypeAndVersioning[l][a]}unbind(){this.node=null,this.getValue=this._getValue_unbound,this.setValue=this._setValue_unbound}};wt.Composite=rh;wt.prototype.BindingType={Direct:0,EntireArray:1,ArrayElement:2,HasFromToArray:3};wt.prototype.Versioning={None:0,NeedsUpdate:1,MatrixWorldNeedsUpdate:2};wt.prototype.GetterByBindingType=[wt.prototype._getValue_direct,wt.prototype._getValue_array,wt.prototype._getValue_arrayElement,wt.prototype._getValue_toArray];wt.prototype.SetterByBindingTypeAndVersioning=[[wt.prototype._setValue_direct,wt.prototype._setValue_direct_setNeedsUpdate,wt.prototype._setValue_direct_setMatrixWorldNeedsUpdate],[wt.prototype._setValue_array,wt.prototype._setValue_array_setNeedsUpdate,wt.prototype._setValue_array_setMatrixWorldNeedsUpdate],[wt.prototype._setValue_arrayElement,wt.prototype._setValue_arrayElement_setNeedsUpdate,wt.prototype._setValue_arrayElement_setMatrixWorldNeedsUpdate],[wt.prototype._setValue_fromArray,wt.prototype._setValue_fromArray_setNeedsUpdate,wt.prototype._setValue_fromArray_setMatrixWorldNeedsUpdate]];var F2=new Float32Array(1);var Io=class{constructor(e=1,n=0,r=0){this.radius=e,this.phi=n,this.theta=r}set(e,n,r){return this.radius=e,this.phi=n,this.theta=r,this}copy(e){return this.radius=e.radius,this.phi=e.phi,this.theta=e.theta,this}makeSafe(){return this.phi=Qe(this.phi,1e-6,Math.PI-1e-6),this}setFromVector3(e){return this.setFromCartesianCoords(e.x,e.y,e.z)}setFromCartesianCoords(e,n,r){return this.radius=Math.sqrt(e*e+n*n+r*r),this.radius===0?(this.theta=0,this.phi=0):(this.theta=Math.atan2(e,r),this.phi=Math.acos(Qe(n/this.radius,-1,1))),this}clone(){return new this.constructor().copy(this)}};var _m=new k,eu,$f,Gs=class extends Xt{constructor(e=new k(0,0,1),n=new k(0,0,0),r=1,i=16776960,o=r*.2,s=o*.2){super(),this.type="ArrowHelper",eu===void 0&&(eu=new cn,eu.setAttribute("position",new qt([0,0,0,0,1,0],3)),$f=new mu(.5,1,5,1),$f.translate(0,-.5,0)),this.position.copy(n),this.line=new Fo(eu,new Ro({color:i,toneMapped:!1})),this.line.matrixAutoUpdate=!1,this.add(this.line),this.cone=new Lt($f,new Ao({color:i,toneMapped:!1})),this.cone.matrixAutoUpdate=!1,this.add(this.cone),this.setDirection(e),this.setLength(r,o,s)}setDirection(e){if(e.y>.99999)this.quaternion.set(0,0,0,1);else if(e.y<-.99999)this.quaternion.set(1,0,0,0);else{_m.set(e.z,0,-e.x).normalize();let n=Math.acos(e.y);this.quaternion.setFromAxisAngle(_m,n)}}setLength(e,n=e*.2,r=n*.2){this.line.scale.set(1,Math.max(1e-4,e-n),1),this.line.updateMatrix(),this.cone.scale.set(r,n,r),this.cone.position.y=e,this.cone.updateMatrix()}setColor(e){this.line.material.color.set(e),this.cone.material.color.set(e)}copy(e){return super.copy(e,!1),this.line.copy(e.line),this.cone.copy(e.cone),this}dispose(){this.line.geometry.dispose(),this.line.material.dispose(),this.cone.geometry.dispose(),this.cone.material.dispose()}};var Ws=class extends ur{constructor(e,n=null){super(),this.object=e,this.domElement=n,this.enabled=!0,this.state=-1,this.keys={},this.mouseButtons={LEFT:null,MIDDLE:null,RIGHT:null},this.touches={ONE:null,TWO:null}}connect(e){if(e===void 0){console.warn("THREE.Controls: connect() now requires an element.");return}this.domElement!==null&&this.disconnect(),this.domElement=e}disconnect(){}dispose(){}update(){}};function Th(t,e,n,r){let i=g1(r);switch(n){case mh:return t*e;case xh:return t*e/i.components*i.byteLength;case Zu:return t*e/i.components*i.byteLength;case vh:return t*e*2/i.components*i.byteLength;case $u:return t*e*2/i.components*i.byteLength;case gh:return t*e*3/i.components*i.byteLength;case Hn:return t*e*4/i.components*i.byteLength;case Ju:return t*e*4/i.components*i.byteLength;case Ys:case Zs:return Math.floor((t+3)/4)*Math.floor((e+3)/4)*8;case $s:case Js:return Math.floor((t+3)/4)*Math.floor((e+3)/4)*16;case Qu:case el:return Math.max(t,16)*Math.max(e,8)/4;case Ku:case ju:return Math.max(t,8)*Math.max(e,8)/2;case tl:case nl:return Math.floor((t+3)/4)*Math.floor((e+3)/4)*8;case rl:return Math.floor((t+3)/4)*Math.floor((e+3)/4)*16;case il:return Math.floor((t+3)/4)*Math.floor((e+3)/4)*16;case ol:return Math.floor((t+4)/5)*Math.floor((e+3)/4)*16;case sl:return Math.floor((t+4)/5)*Math.floor((e+4)/5)*16;case al:return Math.floor((t+5)/6)*Math.floor((e+4)/5)*16;case ul:return Math.floor((t+5)/6)*Math.floor((e+5)/6)*16;case ll:return Math.floor((t+7)/8)*Math.floor((e+4)/5)*16;case cl:return Math.floor((t+7)/8)*Math.floor((e+5)/6)*16;case fl:return Math.floor((t+7)/8)*Math.floor((e+7)/8)*16;case hl:return Math.floor((t+9)/10)*Math.floor((e+4)/5)*16;case dl:return Math.floor((t+9)/10)*Math.floor((e+5)/6)*16;case pl:return Math.floor((t+9)/10)*Math.floor((e+7)/8)*16;case ml:return Math.floor((t+9)/10)*Math.floor((e+9)/10)*16;case gl:return Math.floor((t+11)/12)*Math.floor((e+9)/10)*16;case xl:return Math.floor((t+11)/12)*Math.floor((e+11)/12)*16;case vl:case _l:case yl:return Math.ceil(t/4)*Math.ceil(e/4)*16;case Ml:case Sl:return Math.ceil(t/4)*Math.ceil(e/4)*8;case wl:case bl:return Math.ceil(t/4)*Math.ceil(e/4)*16}throw new Error(`Unable to determine texture byte length for ${n} format.`)}function g1(t){switch(t){case er:case fh:return{byteLength:1,components:1};case No:case hh:case Lo:return{byteLength:2,components:1};case Xu:case Yu:return{byteLength:2,components:4};case ni:case qu:case hr:return{byteLength:4,components:1};case dh:case ph:return{byteLength:4,components:3}}throw new Error(`Unknown texture type ${t}.`)}typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("register",{detail:{revision:"180"}}));typeof window<"u"&&(window.__THREE__?console.warn("WARNING: Multiple instances of Three.js being imported."):window.__THREE__="180");/**
 * @license
 * Copyright 2010-2025 Three.js Authors
 * SPDX-License-Identifier: MIT
 */function Lg(){let t=null,e=!1,n=null,r=null;function i(o,s){n(o,s),r=t.requestAnimationFrame(i)}return{start:function(){e!==!0&&n!==null&&(r=t.requestAnimationFrame(i),e=!0)},stop:function(){t.cancelAnimationFrame(r),e=!1},setAnimationLoop:function(o){n=o},setContext:function(o){t=o}}}function v1(t){let e=new WeakMap;function n(a,l){let u=a.array,c=a.usage,f=u.byteLength,h=t.createBuffer();t.bindBuffer(l,h),t.bufferData(l,u,c),a.onUploadCallback();let d;if(u instanceof Float32Array)d=t.FLOAT;else if(typeof Float16Array<"u"&&u instanceof Float16Array)d=t.HALF_FLOAT;else if(u instanceof Uint16Array)a.isFloat16BufferAttribute?d=t.HALF_FLOAT:d=t.UNSIGNED_SHORT;else if(u instanceof Int16Array)d=t.SHORT;else if(u instanceof Uint32Array)d=t.UNSIGNED_INT;else if(u instanceof Int32Array)d=t.INT;else if(u instanceof Int8Array)d=t.BYTE;else if(u instanceof Uint8Array)d=t.UNSIGNED_BYTE;else if(u instanceof Uint8ClampedArray)d=t.UNSIGNED_BYTE;else throw new Error("THREE.WebGLAttributes: Unsupported buffer data format: "+u);return{buffer:h,type:d,bytesPerElement:u.BYTES_PER_ELEMENT,version:a.version,size:f}}function r(a,l,u){let c=l.array,f=l.updateRanges;if(t.bindBuffer(u,a),f.length===0)t.bufferSubData(u,0,c);else{f.sort((d,x)=>d.start-x.start);let h=0;for(let d=1;d<f.length;d++){let x=f[h],p=f[d];p.start<=x.start+x.count+1?x.count=Math.max(x.count,p.start+p.count-x.start):(++h,f[h]=p)}f.length=h+1;for(let d=0,x=f.length;d<x;d++){let p=f[d];t.bufferSubData(u,p.start*c.BYTES_PER_ELEMENT,c,p.start,p.count)}l.clearUpdateRanges()}l.onUploadCallback()}function i(a){return a.isInterleavedBufferAttribute&&(a=a.data),e.get(a)}function o(a){a.isInterleavedBufferAttribute&&(a=a.data);let l=e.get(a);l&&(t.deleteBuffer(l.buffer),e.delete(a))}function s(a,l){if(a.isInterleavedBufferAttribute&&(a=a.data),a.isGLBufferAttribute){let c=e.get(a);(!c||c.version<a.version)&&e.set(a,{buffer:a.buffer,type:a.type,bytesPerElement:a.elementSize,version:a.version});return}let u=e.get(a);if(u===void 0)e.set(a,n(a,l));else if(u.version<a.version){if(u.size!==a.array.byteLength)throw new Error("THREE.WebGLAttributes: The size of the buffer attribute's array buffer does not match the original size. Resizing buffer attributes is not supported.");r(u.buffer,a,l),u.version=a.version}}return{get:i,remove:o,update:s}}var _1=`#ifdef USE_ALPHAHASH
	if ( diffuseColor.a < getAlphaHashThreshold( vPosition ) ) discard;
#endif`,y1=`#ifdef USE_ALPHAHASH
	const float ALPHA_HASH_SCALE = 0.05;
	float hash2D( vec2 value ) {
		return fract( 1.0e4 * sin( 17.0 * value.x + 0.1 * value.y ) * ( 0.1 + abs( sin( 13.0 * value.y + value.x ) ) ) );
	}
	float hash3D( vec3 value ) {
		return hash2D( vec2( hash2D( value.xy ), value.z ) );
	}
	float getAlphaHashThreshold( vec3 position ) {
		float maxDeriv = max(
			length( dFdx( position.xyz ) ),
			length( dFdy( position.xyz ) )
		);
		float pixScale = 1.0 / ( ALPHA_HASH_SCALE * maxDeriv );
		vec2 pixScales = vec2(
			exp2( floor( log2( pixScale ) ) ),
			exp2( ceil( log2( pixScale ) ) )
		);
		vec2 alpha = vec2(
			hash3D( floor( pixScales.x * position.xyz ) ),
			hash3D( floor( pixScales.y * position.xyz ) )
		);
		float lerpFactor = fract( log2( pixScale ) );
		float x = ( 1.0 - lerpFactor ) * alpha.x + lerpFactor * alpha.y;
		float a = min( lerpFactor, 1.0 - lerpFactor );
		vec3 cases = vec3(
			x * x / ( 2.0 * a * ( 1.0 - a ) ),
			( x - 0.5 * a ) / ( 1.0 - a ),
			1.0 - ( ( 1.0 - x ) * ( 1.0 - x ) / ( 2.0 * a * ( 1.0 - a ) ) )
		);
		float threshold = ( x < ( 1.0 - a ) )
			? ( ( x < a ) ? cases.x : cases.y )
			: cases.z;
		return clamp( threshold , 1.0e-6, 1.0 );
	}
#endif`,M1=`#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, vAlphaMapUv ).g;
#endif`,S1=`#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,w1=`#ifdef USE_ALPHATEST
	#ifdef ALPHA_TO_COVERAGE
	diffuseColor.a = smoothstep( alphaTest, alphaTest + fwidth( diffuseColor.a ), diffuseColor.a );
	if ( diffuseColor.a == 0.0 ) discard;
	#else
	if ( diffuseColor.a < alphaTest ) discard;
	#endif
#endif`,b1=`#ifdef USE_ALPHATEST
	uniform float alphaTest;
#endif`,E1=`#ifdef USE_AOMAP
	float ambientOcclusion = ( texture2D( aoMap, vAoMapUv ).r - 1.0 ) * aoMapIntensity + 1.0;
	reflectedLight.indirectDiffuse *= ambientOcclusion;
	#if defined( USE_CLEARCOAT ) 
		clearcoatSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_SHEEN ) 
		sheenSpecularIndirect *= ambientOcclusion;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD )
		float dotNV = saturate( dot( geometryNormal, geometryViewDir ) );
		reflectedLight.indirectSpecular *= computeSpecularOcclusion( dotNV, ambientOcclusion, material.roughness );
	#endif
#endif`,D1=`#ifdef USE_AOMAP
	uniform sampler2D aoMap;
	uniform float aoMapIntensity;
#endif`,A1=`#ifdef USE_BATCHING
	#if ! defined( GL_ANGLE_multi_draw )
	#define gl_DrawID _gl_DrawID
	uniform int _gl_DrawID;
	#endif
	uniform highp sampler2D batchingTexture;
	uniform highp usampler2D batchingIdTexture;
	mat4 getBatchingMatrix( const in float i ) {
		int size = textureSize( batchingTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( batchingTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( batchingTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( batchingTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( batchingTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
	float getIndirectIndex( const in int i ) {
		int size = textureSize( batchingIdTexture, 0 ).x;
		int x = i % size;
		int y = i / size;
		return float( texelFetch( batchingIdTexture, ivec2( x, y ), 0 ).r );
	}
#endif
#ifdef USE_BATCHING_COLOR
	uniform sampler2D batchingColorTexture;
	vec3 getBatchingColor( const in float i ) {
		int size = textureSize( batchingColorTexture, 0 ).x;
		int j = int( i );
		int x = j % size;
		int y = j / size;
		return texelFetch( batchingColorTexture, ivec2( x, y ), 0 ).rgb;
	}
#endif`,C1=`#ifdef USE_BATCHING
	mat4 batchingMatrix = getBatchingMatrix( getIndirectIndex( gl_DrawID ) );
#endif`,T1=`vec3 transformed = vec3( position );
#ifdef USE_ALPHAHASH
	vPosition = vec3( position );
#endif`,R1=`vec3 objectNormal = vec3( normal );
#ifdef USE_TANGENT
	vec3 objectTangent = vec3( tangent.xyz );
#endif`,F1=`float G_BlinnPhong_Implicit( ) {
	return 0.25;
}
float D_BlinnPhong( const in float shininess, const in float dotNH ) {
	return RECIPROCAL_PI * ( shininess * 0.5 + 1.0 ) * pow( dotNH, shininess );
}
vec3 BRDF_BlinnPhong( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in vec3 specularColor, const in float shininess ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( specularColor, 1.0, dotVH );
	float G = G_BlinnPhong_Implicit( );
	float D = D_BlinnPhong( shininess, dotNH );
	return F * ( G * D );
} // validated`,P1=`#ifdef USE_IRIDESCENCE
	const mat3 XYZ_TO_REC709 = mat3(
		 3.2404542, -0.9692660,  0.0556434,
		-1.5371385,  1.8760108, -0.2040259,
		-0.4985314,  0.0415560,  1.0572252
	);
	vec3 Fresnel0ToIor( vec3 fresnel0 ) {
		vec3 sqrtF0 = sqrt( fresnel0 );
		return ( vec3( 1.0 ) + sqrtF0 ) / ( vec3( 1.0 ) - sqrtF0 );
	}
	vec3 IorToFresnel0( vec3 transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - vec3( incidentIor ) ) / ( transmittedIor + vec3( incidentIor ) ) );
	}
	float IorToFresnel0( float transmittedIor, float incidentIor ) {
		return pow2( ( transmittedIor - incidentIor ) / ( transmittedIor + incidentIor ));
	}
	vec3 evalSensitivity( float OPD, vec3 shift ) {
		float phase = 2.0 * PI * OPD * 1.0e-9;
		vec3 val = vec3( 5.4856e-13, 4.4201e-13, 5.2481e-13 );
		vec3 pos = vec3( 1.6810e+06, 1.7953e+06, 2.2084e+06 );
		vec3 var = vec3( 4.3278e+09, 9.3046e+09, 6.6121e+09 );
		vec3 xyz = val * sqrt( 2.0 * PI * var ) * cos( pos * phase + shift ) * exp( - pow2( phase ) * var );
		xyz.x += 9.7470e-14 * sqrt( 2.0 * PI * 4.5282e+09 ) * cos( 2.2399e+06 * phase + shift[ 0 ] ) * exp( - 4.5282e+09 * pow2( phase ) );
		xyz /= 1.0685e-7;
		vec3 rgb = XYZ_TO_REC709 * xyz;
		return rgb;
	}
	vec3 evalIridescence( float outsideIOR, float eta2, float cosTheta1, float thinFilmThickness, vec3 baseF0 ) {
		vec3 I;
		float iridescenceIOR = mix( outsideIOR, eta2, smoothstep( 0.0, 0.03, thinFilmThickness ) );
		float sinTheta2Sq = pow2( outsideIOR / iridescenceIOR ) * ( 1.0 - pow2( cosTheta1 ) );
		float cosTheta2Sq = 1.0 - sinTheta2Sq;
		if ( cosTheta2Sq < 0.0 ) {
			return vec3( 1.0 );
		}
		float cosTheta2 = sqrt( cosTheta2Sq );
		float R0 = IorToFresnel0( iridescenceIOR, outsideIOR );
		float R12 = F_Schlick( R0, 1.0, cosTheta1 );
		float T121 = 1.0 - R12;
		float phi12 = 0.0;
		if ( iridescenceIOR < outsideIOR ) phi12 = PI;
		float phi21 = PI - phi12;
		vec3 baseIOR = Fresnel0ToIor( clamp( baseF0, 0.0, 0.9999 ) );		vec3 R1 = IorToFresnel0( baseIOR, iridescenceIOR );
		vec3 R23 = F_Schlick( R1, 1.0, cosTheta2 );
		vec3 phi23 = vec3( 0.0 );
		if ( baseIOR[ 0 ] < iridescenceIOR ) phi23[ 0 ] = PI;
		if ( baseIOR[ 1 ] < iridescenceIOR ) phi23[ 1 ] = PI;
		if ( baseIOR[ 2 ] < iridescenceIOR ) phi23[ 2 ] = PI;
		float OPD = 2.0 * iridescenceIOR * thinFilmThickness * cosTheta2;
		vec3 phi = vec3( phi21 ) + phi23;
		vec3 R123 = clamp( R12 * R23, 1e-5, 0.9999 );
		vec3 r123 = sqrt( R123 );
		vec3 Rs = pow2( T121 ) * R23 / ( vec3( 1.0 ) - R123 );
		vec3 C0 = R12 + Rs;
		I = C0;
		vec3 Cm = Rs - T121;
		for ( int m = 1; m <= 2; ++ m ) {
			Cm *= r123;
			vec3 Sm = 2.0 * evalSensitivity( float( m ) * OPD, float( m ) * phi );
			I += Cm * Sm;
		}
		return max( I, vec3( 0.0 ) );
	}
#endif`,I1=`#ifdef USE_BUMPMAP
	uniform sampler2D bumpMap;
	uniform float bumpScale;
	vec2 dHdxy_fwd() {
		vec2 dSTdx = dFdx( vBumpMapUv );
		vec2 dSTdy = dFdy( vBumpMapUv );
		float Hll = bumpScale * texture2D( bumpMap, vBumpMapUv ).x;
		float dBx = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdx ).x - Hll;
		float dBy = bumpScale * texture2D( bumpMap, vBumpMapUv + dSTdy ).x - Hll;
		return vec2( dBx, dBy );
	}
	vec3 perturbNormalArb( vec3 surf_pos, vec3 surf_norm, vec2 dHdxy, float faceDirection ) {
		vec3 vSigmaX = normalize( dFdx( surf_pos.xyz ) );
		vec3 vSigmaY = normalize( dFdy( surf_pos.xyz ) );
		vec3 vN = surf_norm;
		vec3 R1 = cross( vSigmaY, vN );
		vec3 R2 = cross( vN, vSigmaX );
		float fDet = dot( vSigmaX, R1 ) * faceDirection;
		vec3 vGrad = sign( fDet ) * ( dHdxy.x * R1 + dHdxy.y * R2 );
		return normalize( abs( fDet ) * surf_norm - vGrad );
	}
#endif`,N1=`#if NUM_CLIPPING_PLANES > 0
	vec4 plane;
	#ifdef ALPHA_TO_COVERAGE
		float distanceToPlane, distanceGradient;
		float clipOpacity = 1.0;
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
			distanceGradient = fwidth( distanceToPlane ) / 2.0;
			clipOpacity *= smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			if ( clipOpacity == 0.0 ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			float unionClipOpacity = 1.0;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				distanceToPlane = - dot( vClipPosition, plane.xyz ) + plane.w;
				distanceGradient = fwidth( distanceToPlane ) / 2.0;
				unionClipOpacity *= 1.0 - smoothstep( - distanceGradient, distanceGradient, distanceToPlane );
			}
			#pragma unroll_loop_end
			clipOpacity *= 1.0 - unionClipOpacity;
		#endif
		diffuseColor.a *= clipOpacity;
		if ( diffuseColor.a == 0.0 ) discard;
	#else
		#pragma unroll_loop_start
		for ( int i = 0; i < UNION_CLIPPING_PLANES; i ++ ) {
			plane = clippingPlanes[ i ];
			if ( dot( vClipPosition, plane.xyz ) > plane.w ) discard;
		}
		#pragma unroll_loop_end
		#if UNION_CLIPPING_PLANES < NUM_CLIPPING_PLANES
			bool clipped = true;
			#pragma unroll_loop_start
			for ( int i = UNION_CLIPPING_PLANES; i < NUM_CLIPPING_PLANES; i ++ ) {
				plane = clippingPlanes[ i ];
				clipped = ( dot( vClipPosition, plane.xyz ) > plane.w ) && clipped;
			}
			#pragma unroll_loop_end
			if ( clipped ) discard;
		#endif
	#endif
#endif`,L1=`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
	uniform vec4 clippingPlanes[ NUM_CLIPPING_PLANES ];
#endif`,B1=`#if NUM_CLIPPING_PLANES > 0
	varying vec3 vClipPosition;
#endif`,U1=`#if NUM_CLIPPING_PLANES > 0
	vClipPosition = - mvPosition.xyz;
#endif`,O1=`#if defined( USE_COLOR_ALPHA )
	diffuseColor *= vColor;
#elif defined( USE_COLOR )
	diffuseColor.rgb *= vColor;
#endif`,z1=`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR )
	varying vec3 vColor;
#endif`,k1=`#if defined( USE_COLOR_ALPHA )
	varying vec4 vColor;
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	varying vec3 vColor;
#endif`,V1=`#if defined( USE_COLOR_ALPHA )
	vColor = vec4( 1.0 );
#elif defined( USE_COLOR ) || defined( USE_INSTANCING_COLOR ) || defined( USE_BATCHING_COLOR )
	vColor = vec3( 1.0 );
#endif
#ifdef USE_COLOR
	vColor *= color;
#endif
#ifdef USE_INSTANCING_COLOR
	vColor.xyz *= instanceColor.xyz;
#endif
#ifdef USE_BATCHING_COLOR
	vec3 batchingColor = getBatchingColor( getIndirectIndex( gl_DrawID ) );
	vColor.xyz *= batchingColor.xyz;
#endif`,H1=`#define PI 3.141592653589793
#define PI2 6.283185307179586
#define PI_HALF 1.5707963267948966
#define RECIPROCAL_PI 0.3183098861837907
#define RECIPROCAL_PI2 0.15915494309189535
#define EPSILON 1e-6
#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
#define whiteComplement( a ) ( 1.0 - saturate( a ) )
float pow2( const in float x ) { return x*x; }
vec3 pow2( const in vec3 x ) { return x*x; }
float pow3( const in float x ) { return x*x*x; }
float pow4( const in float x ) { float x2 = x*x; return x2*x2; }
float max3( const in vec3 v ) { return max( max( v.x, v.y ), v.z ); }
float average( const in vec3 v ) { return dot( v, vec3( 0.3333333 ) ); }
highp float rand( const in vec2 uv ) {
	const highp float a = 12.9898, b = 78.233, c = 43758.5453;
	highp float dt = dot( uv.xy, vec2( a,b ) ), sn = mod( dt, PI );
	return fract( sin( sn ) * c );
}
#ifdef HIGH_PRECISION
	float precisionSafeLength( vec3 v ) { return length( v ); }
#else
	float precisionSafeLength( vec3 v ) {
		float maxComponent = max3( abs( v ) );
		return length( v / maxComponent ) * maxComponent;
	}
#endif
struct IncidentLight {
	vec3 color;
	vec3 direction;
	bool visible;
};
struct ReflectedLight {
	vec3 directDiffuse;
	vec3 directSpecular;
	vec3 indirectDiffuse;
	vec3 indirectSpecular;
};
#ifdef USE_ALPHAHASH
	varying vec3 vPosition;
#endif
vec3 transformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( matrix * vec4( dir, 0.0 ) ).xyz );
}
vec3 inverseTransformDirection( in vec3 dir, in mat4 matrix ) {
	return normalize( ( vec4( dir, 0.0 ) * matrix ).xyz );
}
mat3 transposeMat3( const in mat3 m ) {
	mat3 tmp;
	tmp[ 0 ] = vec3( m[ 0 ].x, m[ 1 ].x, m[ 2 ].x );
	tmp[ 1 ] = vec3( m[ 0 ].y, m[ 1 ].y, m[ 2 ].y );
	tmp[ 2 ] = vec3( m[ 0 ].z, m[ 1 ].z, m[ 2 ].z );
	return tmp;
}
bool isPerspectiveMatrix( mat4 m ) {
	return m[ 2 ][ 3 ] == - 1.0;
}
vec2 equirectUv( in vec3 dir ) {
	float u = atan( dir.z, dir.x ) * RECIPROCAL_PI2 + 0.5;
	float v = asin( clamp( dir.y, - 1.0, 1.0 ) ) * RECIPROCAL_PI + 0.5;
	return vec2( u, v );
}
vec3 BRDF_Lambert( const in vec3 diffuseColor ) {
	return RECIPROCAL_PI * diffuseColor;
}
vec3 F_Schlick( const in vec3 f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
}
float F_Schlick( const in float f0, const in float f90, const in float dotVH ) {
	float fresnel = exp2( ( - 5.55473 * dotVH - 6.98316 ) * dotVH );
	return f0 * ( 1.0 - fresnel ) + ( f90 * fresnel );
} // validated`,G1=`#ifdef ENVMAP_TYPE_CUBE_UV
	#define cubeUV_minMipLevel 4.0
	#define cubeUV_minTileSize 16.0
	float getFace( vec3 direction ) {
		vec3 absDirection = abs( direction );
		float face = - 1.0;
		if ( absDirection.x > absDirection.z ) {
			if ( absDirection.x > absDirection.y )
				face = direction.x > 0.0 ? 0.0 : 3.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		} else {
			if ( absDirection.z > absDirection.y )
				face = direction.z > 0.0 ? 2.0 : 5.0;
			else
				face = direction.y > 0.0 ? 1.0 : 4.0;
		}
		return face;
	}
	vec2 getUV( vec3 direction, float face ) {
		vec2 uv;
		if ( face == 0.0 ) {
			uv = vec2( direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 1.0 ) {
			uv = vec2( - direction.x, - direction.z ) / abs( direction.y );
		} else if ( face == 2.0 ) {
			uv = vec2( - direction.x, direction.y ) / abs( direction.z );
		} else if ( face == 3.0 ) {
			uv = vec2( - direction.z, direction.y ) / abs( direction.x );
		} else if ( face == 4.0 ) {
			uv = vec2( - direction.x, direction.z ) / abs( direction.y );
		} else {
			uv = vec2( direction.x, direction.y ) / abs( direction.z );
		}
		return 0.5 * ( uv + 1.0 );
	}
	vec3 bilinearCubeUV( sampler2D envMap, vec3 direction, float mipInt ) {
		float face = getFace( direction );
		float filterInt = max( cubeUV_minMipLevel - mipInt, 0.0 );
		mipInt = max( mipInt, cubeUV_minMipLevel );
		float faceSize = exp2( mipInt );
		highp vec2 uv = getUV( direction, face ) * ( faceSize - 2.0 ) + 1.0;
		if ( face > 2.0 ) {
			uv.y += faceSize;
			face -= 3.0;
		}
		uv.x += face * faceSize;
		uv.x += filterInt * 3.0 * cubeUV_minTileSize;
		uv.y += 4.0 * ( exp2( CUBEUV_MAX_MIP ) - faceSize );
		uv.x *= CUBEUV_TEXEL_WIDTH;
		uv.y *= CUBEUV_TEXEL_HEIGHT;
		#ifdef texture2DGradEXT
			return texture2DGradEXT( envMap, uv, vec2( 0.0 ), vec2( 0.0 ) ).rgb;
		#else
			return texture2D( envMap, uv ).rgb;
		#endif
	}
	#define cubeUV_r0 1.0
	#define cubeUV_m0 - 2.0
	#define cubeUV_r1 0.8
	#define cubeUV_m1 - 1.0
	#define cubeUV_r4 0.4
	#define cubeUV_m4 2.0
	#define cubeUV_r5 0.305
	#define cubeUV_m5 3.0
	#define cubeUV_r6 0.21
	#define cubeUV_m6 4.0
	float roughnessToMip( float roughness ) {
		float mip = 0.0;
		if ( roughness >= cubeUV_r1 ) {
			mip = ( cubeUV_r0 - roughness ) * ( cubeUV_m1 - cubeUV_m0 ) / ( cubeUV_r0 - cubeUV_r1 ) + cubeUV_m0;
		} else if ( roughness >= cubeUV_r4 ) {
			mip = ( cubeUV_r1 - roughness ) * ( cubeUV_m4 - cubeUV_m1 ) / ( cubeUV_r1 - cubeUV_r4 ) + cubeUV_m1;
		} else if ( roughness >= cubeUV_r5 ) {
			mip = ( cubeUV_r4 - roughness ) * ( cubeUV_m5 - cubeUV_m4 ) / ( cubeUV_r4 - cubeUV_r5 ) + cubeUV_m4;
		} else if ( roughness >= cubeUV_r6 ) {
			mip = ( cubeUV_r5 - roughness ) * ( cubeUV_m6 - cubeUV_m5 ) / ( cubeUV_r5 - cubeUV_r6 ) + cubeUV_m5;
		} else {
			mip = - 2.0 * log2( 1.16 * roughness );		}
		return mip;
	}
	vec4 textureCubeUV( sampler2D envMap, vec3 sampleDir, float roughness ) {
		float mip = clamp( roughnessToMip( roughness ), cubeUV_m0, CUBEUV_MAX_MIP );
		float mipF = fract( mip );
		float mipInt = floor( mip );
		vec3 color0 = bilinearCubeUV( envMap, sampleDir, mipInt );
		if ( mipF == 0.0 ) {
			return vec4( color0, 1.0 );
		} else {
			vec3 color1 = bilinearCubeUV( envMap, sampleDir, mipInt + 1.0 );
			return vec4( mix( color0, color1, mipF ), 1.0 );
		}
	}
#endif`,W1=`vec3 transformedNormal = objectNormal;
#ifdef USE_TANGENT
	vec3 transformedTangent = objectTangent;
#endif
#ifdef USE_BATCHING
	mat3 bm = mat3( batchingMatrix );
	transformedNormal /= vec3( dot( bm[ 0 ], bm[ 0 ] ), dot( bm[ 1 ], bm[ 1 ] ), dot( bm[ 2 ], bm[ 2 ] ) );
	transformedNormal = bm * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = bm * transformedTangent;
	#endif
#endif
#ifdef USE_INSTANCING
	mat3 im = mat3( instanceMatrix );
	transformedNormal /= vec3( dot( im[ 0 ], im[ 0 ] ), dot( im[ 1 ], im[ 1 ] ), dot( im[ 2 ], im[ 2 ] ) );
	transformedNormal = im * transformedNormal;
	#ifdef USE_TANGENT
		transformedTangent = im * transformedTangent;
	#endif
#endif
transformedNormal = normalMatrix * transformedNormal;
#ifdef FLIP_SIDED
	transformedNormal = - transformedNormal;
#endif
#ifdef USE_TANGENT
	transformedTangent = ( modelViewMatrix * vec4( transformedTangent, 0.0 ) ).xyz;
	#ifdef FLIP_SIDED
		transformedTangent = - transformedTangent;
	#endif
#endif`,q1=`#ifdef USE_DISPLACEMENTMAP
	uniform sampler2D displacementMap;
	uniform float displacementScale;
	uniform float displacementBias;
#endif`,X1=`#ifdef USE_DISPLACEMENTMAP
	transformed += normalize( objectNormal ) * ( texture2D( displacementMap, vDisplacementMapUv ).x * displacementScale + displacementBias );
#endif`,Y1=`#ifdef USE_EMISSIVEMAP
	vec4 emissiveColor = texture2D( emissiveMap, vEmissiveMapUv );
	#ifdef DECODE_VIDEO_TEXTURE_EMISSIVE
		emissiveColor = sRGBTransferEOTF( emissiveColor );
	#endif
	totalEmissiveRadiance *= emissiveColor.rgb;
#endif`,Z1=`#ifdef USE_EMISSIVEMAP
	uniform sampler2D emissiveMap;
#endif`,$1="gl_FragColor = linearToOutputTexel( gl_FragColor );",J1=`vec4 LinearTransferOETF( in vec4 value ) {
	return value;
}
vec4 sRGBTransferEOTF( in vec4 value ) {
	return vec4( mix( pow( value.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), value.rgb * 0.0773993808, vec3( lessThanEqual( value.rgb, vec3( 0.04045 ) ) ) ), value.a );
}
vec4 sRGBTransferOETF( in vec4 value ) {
	return vec4( mix( pow( value.rgb, vec3( 0.41666 ) ) * 1.055 - vec3( 0.055 ), value.rgb * 12.92, vec3( lessThanEqual( value.rgb, vec3( 0.0031308 ) ) ) ), value.a );
}`,K1=`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vec3 cameraToFrag;
		if ( isOrthographic ) {
			cameraToFrag = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToFrag = normalize( vWorldPosition - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vec3 reflectVec = reflect( cameraToFrag, worldNormal );
		#else
			vec3 reflectVec = refract( cameraToFrag, worldNormal, refractionRatio );
		#endif
	#else
		vec3 reflectVec = vReflect;
	#endif
	#ifdef ENVMAP_TYPE_CUBE
		vec4 envColor = textureCube( envMap, envMapRotation * vec3( flipEnvMap * reflectVec.x, reflectVec.yz ) );
	#else
		vec4 envColor = vec4( 0.0 );
	#endif
	#ifdef ENVMAP_BLENDING_MULTIPLY
		outgoingLight = mix( outgoingLight, outgoingLight * envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_MIX )
		outgoingLight = mix( outgoingLight, envColor.xyz, specularStrength * reflectivity );
	#elif defined( ENVMAP_BLENDING_ADD )
		outgoingLight += envColor.xyz * specularStrength * reflectivity;
	#endif
#endif`,Q1=`#ifdef USE_ENVMAP
	uniform float envMapIntensity;
	uniform float flipEnvMap;
	uniform mat3 envMapRotation;
	#ifdef ENVMAP_TYPE_CUBE
		uniform samplerCube envMap;
	#else
		uniform sampler2D envMap;
	#endif
	
#endif`,j1=`#ifdef USE_ENVMAP
	uniform float reflectivity;
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		varying vec3 vWorldPosition;
		uniform float refractionRatio;
	#else
		varying vec3 vReflect;
	#endif
#endif`,eM=`#ifdef USE_ENVMAP
	#if defined( USE_BUMPMAP ) || defined( USE_NORMALMAP ) || defined( PHONG ) || defined( LAMBERT )
		#define ENV_WORLDPOS
	#endif
	#ifdef ENV_WORLDPOS
		
		varying vec3 vWorldPosition;
	#else
		varying vec3 vReflect;
		uniform float refractionRatio;
	#endif
#endif`,tM=`#ifdef USE_ENVMAP
	#ifdef ENV_WORLDPOS
		vWorldPosition = worldPosition.xyz;
	#else
		vec3 cameraToVertex;
		if ( isOrthographic ) {
			cameraToVertex = normalize( vec3( - viewMatrix[ 0 ][ 2 ], - viewMatrix[ 1 ][ 2 ], - viewMatrix[ 2 ][ 2 ] ) );
		} else {
			cameraToVertex = normalize( worldPosition.xyz - cameraPosition );
		}
		vec3 worldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
		#ifdef ENVMAP_MODE_REFLECTION
			vReflect = reflect( cameraToVertex, worldNormal );
		#else
			vReflect = refract( cameraToVertex, worldNormal, refractionRatio );
		#endif
	#endif
#endif`,nM=`#ifdef USE_FOG
	vFogDepth = - mvPosition.z;
#endif`,rM=`#ifdef USE_FOG
	varying float vFogDepth;
#endif`,iM=`#ifdef USE_FOG
	#ifdef FOG_EXP2
		float fogFactor = 1.0 - exp( - fogDensity * fogDensity * vFogDepth * vFogDepth );
	#else
		float fogFactor = smoothstep( fogNear, fogFar, vFogDepth );
	#endif
	gl_FragColor.rgb = mix( gl_FragColor.rgb, fogColor, fogFactor );
#endif`,oM=`#ifdef USE_FOG
	uniform vec3 fogColor;
	varying float vFogDepth;
	#ifdef FOG_EXP2
		uniform float fogDensity;
	#else
		uniform float fogNear;
		uniform float fogFar;
	#endif
#endif`,sM=`#ifdef USE_GRADIENTMAP
	uniform sampler2D gradientMap;
#endif
vec3 getGradientIrradiance( vec3 normal, vec3 lightDirection ) {
	float dotNL = dot( normal, lightDirection );
	vec2 coord = vec2( dotNL * 0.5 + 0.5, 0.0 );
	#ifdef USE_GRADIENTMAP
		return vec3( texture2D( gradientMap, coord ).r );
	#else
		vec2 fw = fwidth( coord ) * 0.5;
		return mix( vec3( 0.7 ), vec3( 1.0 ), smoothstep( 0.7 - fw.x, 0.7 + fw.x, coord.x ) );
	#endif
}`,aM=`#ifdef USE_LIGHTMAP
	uniform sampler2D lightMap;
	uniform float lightMapIntensity;
#endif`,uM=`LambertMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularStrength = specularStrength;`,lM=`varying vec3 vViewPosition;
struct LambertMaterial {
	vec3 diffuseColor;
	float specularStrength;
};
void RE_Direct_Lambert( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Lambert( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in LambertMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Lambert
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Lambert`,cM=`uniform bool receiveShadow;
uniform vec3 ambientLightColor;
#if defined( USE_LIGHT_PROBES )
	uniform vec3 lightProbe[ 9 ];
#endif
vec3 shGetIrradianceAt( in vec3 normal, in vec3 shCoefficients[ 9 ] ) {
	float x = normal.x, y = normal.y, z = normal.z;
	vec3 result = shCoefficients[ 0 ] * 0.886227;
	result += shCoefficients[ 1 ] * 2.0 * 0.511664 * y;
	result += shCoefficients[ 2 ] * 2.0 * 0.511664 * z;
	result += shCoefficients[ 3 ] * 2.0 * 0.511664 * x;
	result += shCoefficients[ 4 ] * 2.0 * 0.429043 * x * y;
	result += shCoefficients[ 5 ] * 2.0 * 0.429043 * y * z;
	result += shCoefficients[ 6 ] * ( 0.743125 * z * z - 0.247708 );
	result += shCoefficients[ 7 ] * 2.0 * 0.429043 * x * z;
	result += shCoefficients[ 8 ] * 0.429043 * ( x * x - y * y );
	return result;
}
vec3 getLightProbeIrradiance( const in vec3 lightProbe[ 9 ], const in vec3 normal ) {
	vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
	vec3 irradiance = shGetIrradianceAt( worldNormal, lightProbe );
	return irradiance;
}
vec3 getAmbientLightIrradiance( const in vec3 ambientLightColor ) {
	vec3 irradiance = ambientLightColor;
	return irradiance;
}
float getDistanceAttenuation( const in float lightDistance, const in float cutoffDistance, const in float decayExponent ) {
	float distanceFalloff = 1.0 / max( pow( lightDistance, decayExponent ), 0.01 );
	if ( cutoffDistance > 0.0 ) {
		distanceFalloff *= pow2( saturate( 1.0 - pow4( lightDistance / cutoffDistance ) ) );
	}
	return distanceFalloff;
}
float getSpotAttenuation( const in float coneCosine, const in float penumbraCosine, const in float angleCosine ) {
	return smoothstep( coneCosine, penumbraCosine, angleCosine );
}
#if NUM_DIR_LIGHTS > 0
	struct DirectionalLight {
		vec3 direction;
		vec3 color;
	};
	uniform DirectionalLight directionalLights[ NUM_DIR_LIGHTS ];
	void getDirectionalLightInfo( const in DirectionalLight directionalLight, out IncidentLight light ) {
		light.color = directionalLight.color;
		light.direction = directionalLight.direction;
		light.visible = true;
	}
#endif
#if NUM_POINT_LIGHTS > 0
	struct PointLight {
		vec3 position;
		vec3 color;
		float distance;
		float decay;
	};
	uniform PointLight pointLights[ NUM_POINT_LIGHTS ];
	void getPointLightInfo( const in PointLight pointLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = pointLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float lightDistance = length( lVector );
		light.color = pointLight.color;
		light.color *= getDistanceAttenuation( lightDistance, pointLight.distance, pointLight.decay );
		light.visible = ( light.color != vec3( 0.0 ) );
	}
#endif
#if NUM_SPOT_LIGHTS > 0
	struct SpotLight {
		vec3 position;
		vec3 direction;
		vec3 color;
		float distance;
		float decay;
		float coneCos;
		float penumbraCos;
	};
	uniform SpotLight spotLights[ NUM_SPOT_LIGHTS ];
	void getSpotLightInfo( const in SpotLight spotLight, const in vec3 geometryPosition, out IncidentLight light ) {
		vec3 lVector = spotLight.position - geometryPosition;
		light.direction = normalize( lVector );
		float angleCos = dot( light.direction, spotLight.direction );
		float spotAttenuation = getSpotAttenuation( spotLight.coneCos, spotLight.penumbraCos, angleCos );
		if ( spotAttenuation > 0.0 ) {
			float lightDistance = length( lVector );
			light.color = spotLight.color * spotAttenuation;
			light.color *= getDistanceAttenuation( lightDistance, spotLight.distance, spotLight.decay );
			light.visible = ( light.color != vec3( 0.0 ) );
		} else {
			light.color = vec3( 0.0 );
			light.visible = false;
		}
	}
#endif
#if NUM_RECT_AREA_LIGHTS > 0
	struct RectAreaLight {
		vec3 color;
		vec3 position;
		vec3 halfWidth;
		vec3 halfHeight;
	};
	uniform sampler2D ltc_1;	uniform sampler2D ltc_2;
	uniform RectAreaLight rectAreaLights[ NUM_RECT_AREA_LIGHTS ];
#endif
#if NUM_HEMI_LIGHTS > 0
	struct HemisphereLight {
		vec3 direction;
		vec3 skyColor;
		vec3 groundColor;
	};
	uniform HemisphereLight hemisphereLights[ NUM_HEMI_LIGHTS ];
	vec3 getHemisphereLightIrradiance( const in HemisphereLight hemiLight, const in vec3 normal ) {
		float dotNL = dot( normal, hemiLight.direction );
		float hemiDiffuseWeight = 0.5 * dotNL + 0.5;
		vec3 irradiance = mix( hemiLight.groundColor, hemiLight.skyColor, hemiDiffuseWeight );
		return irradiance;
	}
#endif`,fM=`#ifdef USE_ENVMAP
	vec3 getIBLIrradiance( const in vec3 normal ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 worldNormal = inverseTransformDirection( normal, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * worldNormal, 1.0 );
			return PI * envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	vec3 getIBLRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness ) {
		#ifdef ENVMAP_TYPE_CUBE_UV
			vec3 reflectVec = reflect( - viewDir, normal );
			reflectVec = normalize( mix( reflectVec, normal, roughness * roughness) );
			reflectVec = inverseTransformDirection( reflectVec, viewMatrix );
			vec4 envMapColor = textureCubeUV( envMap, envMapRotation * reflectVec, roughness );
			return envMapColor.rgb * envMapIntensity;
		#else
			return vec3( 0.0 );
		#endif
	}
	#ifdef USE_ANISOTROPY
		vec3 getIBLAnisotropyRadiance( const in vec3 viewDir, const in vec3 normal, const in float roughness, const in vec3 bitangent, const in float anisotropy ) {
			#ifdef ENVMAP_TYPE_CUBE_UV
				vec3 bentNormal = cross( bitangent, viewDir );
				bentNormal = normalize( cross( bentNormal, bitangent ) );
				bentNormal = normalize( mix( bentNormal, normal, pow2( pow2( 1.0 - anisotropy * ( 1.0 - roughness ) ) ) ) );
				return getIBLRadiance( viewDir, bentNormal, roughness );
			#else
				return vec3( 0.0 );
			#endif
		}
	#endif
#endif`,hM=`ToonMaterial material;
material.diffuseColor = diffuseColor.rgb;`,dM=`varying vec3 vViewPosition;
struct ToonMaterial {
	vec3 diffuseColor;
};
void RE_Direct_Toon( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	vec3 irradiance = getGradientIrradiance( geometryNormal, directLight.direction ) * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Toon( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in ToonMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_Toon
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Toon`,pM=`BlinnPhongMaterial material;
material.diffuseColor = diffuseColor.rgb;
material.specularColor = specular;
material.specularShininess = shininess;
material.specularStrength = specularStrength;`,mM=`varying vec3 vViewPosition;
struct BlinnPhongMaterial {
	vec3 diffuseColor;
	vec3 specularColor;
	float specularShininess;
	float specularStrength;
};
void RE_Direct_BlinnPhong( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
	reflectedLight.directSpecular += irradiance * BRDF_BlinnPhong( directLight.direction, geometryViewDir, geometryNormal, material.specularColor, material.specularShininess ) * material.specularStrength;
}
void RE_IndirectDiffuse_BlinnPhong( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in BlinnPhongMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
#define RE_Direct				RE_Direct_BlinnPhong
#define RE_IndirectDiffuse		RE_IndirectDiffuse_BlinnPhong`,gM=`PhysicalMaterial material;
material.diffuseColor = diffuseColor.rgb * ( 1.0 - metalnessFactor );
vec3 dxy = max( abs( dFdx( nonPerturbedNormal ) ), abs( dFdy( nonPerturbedNormal ) ) );
float geometryRoughness = max( max( dxy.x, dxy.y ), dxy.z );
material.roughness = max( roughnessFactor, 0.0525 );material.roughness += geometryRoughness;
material.roughness = min( material.roughness, 1.0 );
#ifdef IOR
	material.ior = ior;
	#ifdef USE_SPECULAR
		float specularIntensityFactor = specularIntensity;
		vec3 specularColorFactor = specularColor;
		#ifdef USE_SPECULAR_COLORMAP
			specularColorFactor *= texture2D( specularColorMap, vSpecularColorMapUv ).rgb;
		#endif
		#ifdef USE_SPECULAR_INTENSITYMAP
			specularIntensityFactor *= texture2D( specularIntensityMap, vSpecularIntensityMapUv ).a;
		#endif
		material.specularF90 = mix( specularIntensityFactor, 1.0, metalnessFactor );
	#else
		float specularIntensityFactor = 1.0;
		vec3 specularColorFactor = vec3( 1.0 );
		material.specularF90 = 1.0;
	#endif
	material.specularColor = mix( min( pow2( ( material.ior - 1.0 ) / ( material.ior + 1.0 ) ) * specularColorFactor, vec3( 1.0 ) ) * specularIntensityFactor, diffuseColor.rgb, metalnessFactor );
#else
	material.specularColor = mix( vec3( 0.04 ), diffuseColor.rgb, metalnessFactor );
	material.specularF90 = 1.0;
#endif
#ifdef USE_CLEARCOAT
	material.clearcoat = clearcoat;
	material.clearcoatRoughness = clearcoatRoughness;
	material.clearcoatF0 = vec3( 0.04 );
	material.clearcoatF90 = 1.0;
	#ifdef USE_CLEARCOATMAP
		material.clearcoat *= texture2D( clearcoatMap, vClearcoatMapUv ).x;
	#endif
	#ifdef USE_CLEARCOAT_ROUGHNESSMAP
		material.clearcoatRoughness *= texture2D( clearcoatRoughnessMap, vClearcoatRoughnessMapUv ).y;
	#endif
	material.clearcoat = saturate( material.clearcoat );	material.clearcoatRoughness = max( material.clearcoatRoughness, 0.0525 );
	material.clearcoatRoughness += geometryRoughness;
	material.clearcoatRoughness = min( material.clearcoatRoughness, 1.0 );
#endif
#ifdef USE_DISPERSION
	material.dispersion = dispersion;
#endif
#ifdef USE_IRIDESCENCE
	material.iridescence = iridescence;
	material.iridescenceIOR = iridescenceIOR;
	#ifdef USE_IRIDESCENCEMAP
		material.iridescence *= texture2D( iridescenceMap, vIridescenceMapUv ).r;
	#endif
	#ifdef USE_IRIDESCENCE_THICKNESSMAP
		material.iridescenceThickness = (iridescenceThicknessMaximum - iridescenceThicknessMinimum) * texture2D( iridescenceThicknessMap, vIridescenceThicknessMapUv ).g + iridescenceThicknessMinimum;
	#else
		material.iridescenceThickness = iridescenceThicknessMaximum;
	#endif
#endif
#ifdef USE_SHEEN
	material.sheenColor = sheenColor;
	#ifdef USE_SHEEN_COLORMAP
		material.sheenColor *= texture2D( sheenColorMap, vSheenColorMapUv ).rgb;
	#endif
	material.sheenRoughness = clamp( sheenRoughness, 0.07, 1.0 );
	#ifdef USE_SHEEN_ROUGHNESSMAP
		material.sheenRoughness *= texture2D( sheenRoughnessMap, vSheenRoughnessMapUv ).a;
	#endif
#endif
#ifdef USE_ANISOTROPY
	#ifdef USE_ANISOTROPYMAP
		mat2 anisotropyMat = mat2( anisotropyVector.x, anisotropyVector.y, - anisotropyVector.y, anisotropyVector.x );
		vec3 anisotropyPolar = texture2D( anisotropyMap, vAnisotropyMapUv ).rgb;
		vec2 anisotropyV = anisotropyMat * normalize( 2.0 * anisotropyPolar.rg - vec2( 1.0 ) ) * anisotropyPolar.b;
	#else
		vec2 anisotropyV = anisotropyVector;
	#endif
	material.anisotropy = length( anisotropyV );
	if( material.anisotropy == 0.0 ) {
		anisotropyV = vec2( 1.0, 0.0 );
	} else {
		anisotropyV /= material.anisotropy;
		material.anisotropy = saturate( material.anisotropy );
	}
	material.alphaT = mix( pow2( material.roughness ), 1.0, pow2( material.anisotropy ) );
	material.anisotropyT = tbn[ 0 ] * anisotropyV.x + tbn[ 1 ] * anisotropyV.y;
	material.anisotropyB = tbn[ 1 ] * anisotropyV.x - tbn[ 0 ] * anisotropyV.y;
#endif`,xM=`struct PhysicalMaterial {
	vec3 diffuseColor;
	float roughness;
	vec3 specularColor;
	float specularF90;
	float dispersion;
	#ifdef USE_CLEARCOAT
		float clearcoat;
		float clearcoatRoughness;
		vec3 clearcoatF0;
		float clearcoatF90;
	#endif
	#ifdef USE_IRIDESCENCE
		float iridescence;
		float iridescenceIOR;
		float iridescenceThickness;
		vec3 iridescenceFresnel;
		vec3 iridescenceF0;
	#endif
	#ifdef USE_SHEEN
		vec3 sheenColor;
		float sheenRoughness;
	#endif
	#ifdef IOR
		float ior;
	#endif
	#ifdef USE_TRANSMISSION
		float transmission;
		float transmissionAlpha;
		float thickness;
		float attenuationDistance;
		vec3 attenuationColor;
	#endif
	#ifdef USE_ANISOTROPY
		float anisotropy;
		float alphaT;
		vec3 anisotropyT;
		vec3 anisotropyB;
	#endif
};
vec3 clearcoatSpecularDirect = vec3( 0.0 );
vec3 clearcoatSpecularIndirect = vec3( 0.0 );
vec3 sheenSpecularDirect = vec3( 0.0 );
vec3 sheenSpecularIndirect = vec3(0.0 );
vec3 Schlick_to_F0( const in vec3 f, const in float f90, const in float dotVH ) {
    float x = clamp( 1.0 - dotVH, 0.0, 1.0 );
    float x2 = x * x;
    float x5 = clamp( x * x2 * x2, 0.0, 0.9999 );
    return ( f - vec3( f90 ) * x5 ) / ( 1.0 - x5 );
}
float V_GGX_SmithCorrelated( const in float alpha, const in float dotNL, const in float dotNV ) {
	float a2 = pow2( alpha );
	float gv = dotNL * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNV ) );
	float gl = dotNV * sqrt( a2 + ( 1.0 - a2 ) * pow2( dotNL ) );
	return 0.5 / max( gv + gl, EPSILON );
}
float D_GGX( const in float alpha, const in float dotNH ) {
	float a2 = pow2( alpha );
	float denom = pow2( dotNH ) * ( a2 - 1.0 ) + 1.0;
	return RECIPROCAL_PI * a2 / pow2( denom );
}
#ifdef USE_ANISOTROPY
	float V_GGX_SmithCorrelated_Anisotropic( const in float alphaT, const in float alphaB, const in float dotTV, const in float dotBV, const in float dotTL, const in float dotBL, const in float dotNV, const in float dotNL ) {
		float gv = dotNL * length( vec3( alphaT * dotTV, alphaB * dotBV, dotNV ) );
		float gl = dotNV * length( vec3( alphaT * dotTL, alphaB * dotBL, dotNL ) );
		float v = 0.5 / ( gv + gl );
		return saturate(v);
	}
	float D_GGX_Anisotropic( const in float alphaT, const in float alphaB, const in float dotNH, const in float dotTH, const in float dotBH ) {
		float a2 = alphaT * alphaB;
		highp vec3 v = vec3( alphaB * dotTH, alphaT * dotBH, a2 * dotNH );
		highp float v2 = dot( v, v );
		float w2 = a2 / v2;
		return RECIPROCAL_PI * a2 * pow2 ( w2 );
	}
#endif
#ifdef USE_CLEARCOAT
	vec3 BRDF_GGX_Clearcoat( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material) {
		vec3 f0 = material.clearcoatF0;
		float f90 = material.clearcoatF90;
		float roughness = material.clearcoatRoughness;
		float alpha = pow2( roughness );
		vec3 halfDir = normalize( lightDir + viewDir );
		float dotNL = saturate( dot( normal, lightDir ) );
		float dotNV = saturate( dot( normal, viewDir ) );
		float dotNH = saturate( dot( normal, halfDir ) );
		float dotVH = saturate( dot( viewDir, halfDir ) );
		vec3 F = F_Schlick( f0, f90, dotVH );
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
		return F * ( V * D );
	}
#endif
vec3 BRDF_GGX( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, const in PhysicalMaterial material ) {
	vec3 f0 = material.specularColor;
	float f90 = material.specularF90;
	float roughness = material.roughness;
	float alpha = pow2( roughness );
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float dotVH = saturate( dot( viewDir, halfDir ) );
	vec3 F = F_Schlick( f0, f90, dotVH );
	#ifdef USE_IRIDESCENCE
		F = mix( F, material.iridescenceFresnel, material.iridescence );
	#endif
	#ifdef USE_ANISOTROPY
		float dotTL = dot( material.anisotropyT, lightDir );
		float dotTV = dot( material.anisotropyT, viewDir );
		float dotTH = dot( material.anisotropyT, halfDir );
		float dotBL = dot( material.anisotropyB, lightDir );
		float dotBV = dot( material.anisotropyB, viewDir );
		float dotBH = dot( material.anisotropyB, halfDir );
		float V = V_GGX_SmithCorrelated_Anisotropic( material.alphaT, alpha, dotTV, dotBV, dotTL, dotBL, dotNV, dotNL );
		float D = D_GGX_Anisotropic( material.alphaT, alpha, dotNH, dotTH, dotBH );
	#else
		float V = V_GGX_SmithCorrelated( alpha, dotNL, dotNV );
		float D = D_GGX( alpha, dotNH );
	#endif
	return F * ( V * D );
}
vec2 LTC_Uv( const in vec3 N, const in vec3 V, const in float roughness ) {
	const float LUT_SIZE = 64.0;
	const float LUT_SCALE = ( LUT_SIZE - 1.0 ) / LUT_SIZE;
	const float LUT_BIAS = 0.5 / LUT_SIZE;
	float dotNV = saturate( dot( N, V ) );
	vec2 uv = vec2( roughness, sqrt( 1.0 - dotNV ) );
	uv = uv * LUT_SCALE + LUT_BIAS;
	return uv;
}
float LTC_ClippedSphereFormFactor( const in vec3 f ) {
	float l = length( f );
	return max( ( l * l + f.z ) / ( l + 1.0 ), 0.0 );
}
vec3 LTC_EdgeVectorFormFactor( const in vec3 v1, const in vec3 v2 ) {
	float x = dot( v1, v2 );
	float y = abs( x );
	float a = 0.8543985 + ( 0.4965155 + 0.0145206 * y ) * y;
	float b = 3.4175940 + ( 4.1616724 + y ) * y;
	float v = a / b;
	float theta_sintheta = ( x > 0.0 ) ? v : 0.5 * inversesqrt( max( 1.0 - x * x, 1e-7 ) ) - v;
	return cross( v1, v2 ) * theta_sintheta;
}
vec3 LTC_Evaluate( const in vec3 N, const in vec3 V, const in vec3 P, const in mat3 mInv, const in vec3 rectCoords[ 4 ] ) {
	vec3 v1 = rectCoords[ 1 ] - rectCoords[ 0 ];
	vec3 v2 = rectCoords[ 3 ] - rectCoords[ 0 ];
	vec3 lightNormal = cross( v1, v2 );
	if( dot( lightNormal, P - rectCoords[ 0 ] ) < 0.0 ) return vec3( 0.0 );
	vec3 T1, T2;
	T1 = normalize( V - N * dot( V, N ) );
	T2 = - cross( N, T1 );
	mat3 mat = mInv * transposeMat3( mat3( T1, T2, N ) );
	vec3 coords[ 4 ];
	coords[ 0 ] = mat * ( rectCoords[ 0 ] - P );
	coords[ 1 ] = mat * ( rectCoords[ 1 ] - P );
	coords[ 2 ] = mat * ( rectCoords[ 2 ] - P );
	coords[ 3 ] = mat * ( rectCoords[ 3 ] - P );
	coords[ 0 ] = normalize( coords[ 0 ] );
	coords[ 1 ] = normalize( coords[ 1 ] );
	coords[ 2 ] = normalize( coords[ 2 ] );
	coords[ 3 ] = normalize( coords[ 3 ] );
	vec3 vectorFormFactor = vec3( 0.0 );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 0 ], coords[ 1 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 1 ], coords[ 2 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 2 ], coords[ 3 ] );
	vectorFormFactor += LTC_EdgeVectorFormFactor( coords[ 3 ], coords[ 0 ] );
	float result = LTC_ClippedSphereFormFactor( vectorFormFactor );
	return vec3( result );
}
#if defined( USE_SHEEN )
float D_Charlie( float roughness, float dotNH ) {
	float alpha = pow2( roughness );
	float invAlpha = 1.0 / alpha;
	float cos2h = dotNH * dotNH;
	float sin2h = max( 1.0 - cos2h, 0.0078125 );
	return ( 2.0 + invAlpha ) * pow( sin2h, invAlpha * 0.5 ) / ( 2.0 * PI );
}
float V_Neubelt( float dotNV, float dotNL ) {
	return saturate( 1.0 / ( 4.0 * ( dotNL + dotNV - dotNL * dotNV ) ) );
}
vec3 BRDF_Sheen( const in vec3 lightDir, const in vec3 viewDir, const in vec3 normal, vec3 sheenColor, const in float sheenRoughness ) {
	vec3 halfDir = normalize( lightDir + viewDir );
	float dotNL = saturate( dot( normal, lightDir ) );
	float dotNV = saturate( dot( normal, viewDir ) );
	float dotNH = saturate( dot( normal, halfDir ) );
	float D = D_Charlie( sheenRoughness, dotNH );
	float V = V_Neubelt( dotNV, dotNL );
	return sheenColor * ( D * V );
}
#endif
float IBLSheenBRDF( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	float r2 = roughness * roughness;
	float a = roughness < 0.25 ? -339.2 * r2 + 161.4 * roughness - 25.9 : -8.48 * r2 + 14.3 * roughness - 9.95;
	float b = roughness < 0.25 ? 44.0 * r2 - 23.7 * roughness + 3.26 : 1.97 * r2 - 3.27 * roughness + 0.72;
	float DG = exp( a * dotNV + b ) + ( roughness < 0.25 ? 0.0 : 0.1 * ( roughness - 0.25 ) );
	return saturate( DG * RECIPROCAL_PI );
}
vec2 DFGApprox( const in vec3 normal, const in vec3 viewDir, const in float roughness ) {
	float dotNV = saturate( dot( normal, viewDir ) );
	const vec4 c0 = vec4( - 1, - 0.0275, - 0.572, 0.022 );
	const vec4 c1 = vec4( 1, 0.0425, 1.04, - 0.04 );
	vec4 r = roughness * c0 + c1;
	float a004 = min( r.x * r.x, exp2( - 9.28 * dotNV ) ) * r.x + r.y;
	vec2 fab = vec2( - 1.04, 1.04 ) * a004 + r.zw;
	return fab;
}
vec3 EnvironmentBRDF( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness ) {
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	return specularColor * fab.x + specularF90 * fab.y;
}
#ifdef USE_IRIDESCENCE
void computeMultiscatteringIridescence( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float iridescence, const in vec3 iridescenceF0, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#else
void computeMultiscattering( const in vec3 normal, const in vec3 viewDir, const in vec3 specularColor, const in float specularF90, const in float roughness, inout vec3 singleScatter, inout vec3 multiScatter ) {
#endif
	vec2 fab = DFGApprox( normal, viewDir, roughness );
	#ifdef USE_IRIDESCENCE
		vec3 Fr = mix( specularColor, iridescenceF0, iridescence );
	#else
		vec3 Fr = specularColor;
	#endif
	vec3 FssEss = Fr * fab.x + specularF90 * fab.y;
	float Ess = fab.x + fab.y;
	float Ems = 1.0 - Ess;
	vec3 Favg = Fr + ( 1.0 - Fr ) * 0.047619;	vec3 Fms = FssEss * Favg / ( 1.0 - Ems * Favg );
	singleScatter += FssEss;
	multiScatter += Fms * Ems;
}
#if NUM_RECT_AREA_LIGHTS > 0
	void RE_Direct_RectArea_Physical( const in RectAreaLight rectAreaLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
		vec3 normal = geometryNormal;
		vec3 viewDir = geometryViewDir;
		vec3 position = geometryPosition;
		vec3 lightPos = rectAreaLight.position;
		vec3 halfWidth = rectAreaLight.halfWidth;
		vec3 halfHeight = rectAreaLight.halfHeight;
		vec3 lightColor = rectAreaLight.color;
		float roughness = material.roughness;
		vec3 rectCoords[ 4 ];
		rectCoords[ 0 ] = lightPos + halfWidth - halfHeight;		rectCoords[ 1 ] = lightPos - halfWidth - halfHeight;
		rectCoords[ 2 ] = lightPos - halfWidth + halfHeight;
		rectCoords[ 3 ] = lightPos + halfWidth + halfHeight;
		vec2 uv = LTC_Uv( normal, viewDir, roughness );
		vec4 t1 = texture2D( ltc_1, uv );
		vec4 t2 = texture2D( ltc_2, uv );
		mat3 mInv = mat3(
			vec3( t1.x, 0, t1.y ),
			vec3(    0, 1,    0 ),
			vec3( t1.z, 0, t1.w )
		);
		vec3 fresnel = ( material.specularColor * t2.x + ( vec3( 1.0 ) - material.specularColor ) * t2.y );
		reflectedLight.directSpecular += lightColor * fresnel * LTC_Evaluate( normal, viewDir, position, mInv, rectCoords );
		reflectedLight.directDiffuse += lightColor * material.diffuseColor * LTC_Evaluate( normal, viewDir, position, mat3( 1.0 ), rectCoords );
	}
#endif
void RE_Direct_Physical( const in IncidentLight directLight, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	float dotNL = saturate( dot( geometryNormal, directLight.direction ) );
	vec3 irradiance = dotNL * directLight.color;
	#ifdef USE_CLEARCOAT
		float dotNLcc = saturate( dot( geometryClearcoatNormal, directLight.direction ) );
		vec3 ccIrradiance = dotNLcc * directLight.color;
		clearcoatSpecularDirect += ccIrradiance * BRDF_GGX_Clearcoat( directLight.direction, geometryViewDir, geometryClearcoatNormal, material );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularDirect += irradiance * BRDF_Sheen( directLight.direction, geometryViewDir, geometryNormal, material.sheenColor, material.sheenRoughness );
	#endif
	reflectedLight.directSpecular += irradiance * BRDF_GGX( directLight.direction, geometryViewDir, geometryNormal, material );
	reflectedLight.directDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectDiffuse_Physical( const in vec3 irradiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight ) {
	reflectedLight.indirectDiffuse += irradiance * BRDF_Lambert( material.diffuseColor );
}
void RE_IndirectSpecular_Physical( const in vec3 radiance, const in vec3 irradiance, const in vec3 clearcoatRadiance, const in vec3 geometryPosition, const in vec3 geometryNormal, const in vec3 geometryViewDir, const in vec3 geometryClearcoatNormal, const in PhysicalMaterial material, inout ReflectedLight reflectedLight) {
	#ifdef USE_CLEARCOAT
		clearcoatSpecularIndirect += clearcoatRadiance * EnvironmentBRDF( geometryClearcoatNormal, geometryViewDir, material.clearcoatF0, material.clearcoatF90, material.clearcoatRoughness );
	#endif
	#ifdef USE_SHEEN
		sheenSpecularIndirect += irradiance * material.sheenColor * IBLSheenBRDF( geometryNormal, geometryViewDir, material.sheenRoughness );
	#endif
	vec3 singleScattering = vec3( 0.0 );
	vec3 multiScattering = vec3( 0.0 );
	vec3 cosineWeightedIrradiance = irradiance * RECIPROCAL_PI;
	#ifdef USE_IRIDESCENCE
		computeMultiscatteringIridescence( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.iridescence, material.iridescenceFresnel, material.roughness, singleScattering, multiScattering );
	#else
		computeMultiscattering( geometryNormal, geometryViewDir, material.specularColor, material.specularF90, material.roughness, singleScattering, multiScattering );
	#endif
	vec3 totalScattering = singleScattering + multiScattering;
	vec3 diffuse = material.diffuseColor * ( 1.0 - max( max( totalScattering.r, totalScattering.g ), totalScattering.b ) );
	reflectedLight.indirectSpecular += radiance * singleScattering;
	reflectedLight.indirectSpecular += multiScattering * cosineWeightedIrradiance;
	reflectedLight.indirectDiffuse += diffuse * cosineWeightedIrradiance;
}
#define RE_Direct				RE_Direct_Physical
#define RE_Direct_RectArea		RE_Direct_RectArea_Physical
#define RE_IndirectDiffuse		RE_IndirectDiffuse_Physical
#define RE_IndirectSpecular		RE_IndirectSpecular_Physical
float computeSpecularOcclusion( const in float dotNV, const in float ambientOcclusion, const in float roughness ) {
	return saturate( pow( dotNV + ambientOcclusion, exp2( - 16.0 * roughness - 1.0 ) ) - 1.0 + ambientOcclusion );
}`,vM=`
vec3 geometryPosition = - vViewPosition;
vec3 geometryNormal = normal;
vec3 geometryViewDir = ( isOrthographic ) ? vec3( 0, 0, 1 ) : normalize( vViewPosition );
vec3 geometryClearcoatNormal = vec3( 0.0 );
#ifdef USE_CLEARCOAT
	geometryClearcoatNormal = clearcoatNormal;
#endif
#ifdef USE_IRIDESCENCE
	float dotNVi = saturate( dot( normal, geometryViewDir ) );
	if ( material.iridescenceThickness == 0.0 ) {
		material.iridescence = 0.0;
	} else {
		material.iridescence = saturate( material.iridescence );
	}
	if ( material.iridescence > 0.0 ) {
		material.iridescenceFresnel = evalIridescence( 1.0, material.iridescenceIOR, dotNVi, material.iridescenceThickness, material.specularColor );
		material.iridescenceF0 = Schlick_to_F0( material.iridescenceFresnel, 1.0, dotNVi );
	}
#endif
IncidentLight directLight;
#if ( NUM_POINT_LIGHTS > 0 ) && defined( RE_Direct )
	PointLight pointLight;
	#if defined( USE_SHADOWMAP ) && NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHTS; i ++ ) {
		pointLight = pointLights[ i ];
		getPointLightInfo( pointLight, geometryPosition, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_POINT_LIGHT_SHADOWS )
		pointLightShadow = pointLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getPointShadow( pointShadowMap[ i ], pointLightShadow.shadowMapSize, pointLightShadow.shadowIntensity, pointLightShadow.shadowBias, pointLightShadow.shadowRadius, vPointShadowCoord[ i ], pointLightShadow.shadowCameraNear, pointLightShadow.shadowCameraFar ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_SPOT_LIGHTS > 0 ) && defined( RE_Direct )
	SpotLight spotLight;
	vec4 spotColor;
	vec3 spotLightCoord;
	bool inSpotLightMap;
	#if defined( USE_SHADOWMAP ) && NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHTS; i ++ ) {
		spotLight = spotLights[ i ];
		getSpotLightInfo( spotLight, geometryPosition, directLight );
		#if ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#define SPOT_LIGHT_MAP_INDEX UNROLLED_LOOP_INDEX
		#elif ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		#define SPOT_LIGHT_MAP_INDEX NUM_SPOT_LIGHT_MAPS
		#else
		#define SPOT_LIGHT_MAP_INDEX ( UNROLLED_LOOP_INDEX - NUM_SPOT_LIGHT_SHADOWS + NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS )
		#endif
		#if ( SPOT_LIGHT_MAP_INDEX < NUM_SPOT_LIGHT_MAPS )
			spotLightCoord = vSpotLightCoord[ i ].xyz / vSpotLightCoord[ i ].w;
			inSpotLightMap = all( lessThan( abs( spotLightCoord * 2. - 1. ), vec3( 1.0 ) ) );
			spotColor = texture2D( spotLightMap[ SPOT_LIGHT_MAP_INDEX ], spotLightCoord.xy );
			directLight.color = inSpotLightMap ? directLight.color * spotColor.rgb : directLight.color;
		#endif
		#undef SPOT_LIGHT_MAP_INDEX
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
		spotLightShadow = spotLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( spotShadowMap[ i ], spotLightShadow.shadowMapSize, spotLightShadow.shadowIntensity, spotLightShadow.shadowBias, spotLightShadow.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_DIR_LIGHTS > 0 ) && defined( RE_Direct )
	DirectionalLight directionalLight;
	#if defined( USE_SHADOWMAP ) && NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLightShadow;
	#endif
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHTS; i ++ ) {
		directionalLight = directionalLights[ i ];
		getDirectionalLightInfo( directionalLight, directLight );
		#if defined( USE_SHADOWMAP ) && ( UNROLLED_LOOP_INDEX < NUM_DIR_LIGHT_SHADOWS )
		directionalLightShadow = directionalLightShadows[ i ];
		directLight.color *= ( directLight.visible && receiveShadow ) ? getShadow( directionalShadowMap[ i ], directionalLightShadow.shadowMapSize, directionalLightShadow.shadowIntensity, directionalLightShadow.shadowBias, directionalLightShadow.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
		#endif
		RE_Direct( directLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if ( NUM_RECT_AREA_LIGHTS > 0 ) && defined( RE_Direct_RectArea )
	RectAreaLight rectAreaLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_RECT_AREA_LIGHTS; i ++ ) {
		rectAreaLight = rectAreaLights[ i ];
		RE_Direct_RectArea( rectAreaLight, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
	}
	#pragma unroll_loop_end
#endif
#if defined( RE_IndirectDiffuse )
	vec3 iblIrradiance = vec3( 0.0 );
	vec3 irradiance = getAmbientLightIrradiance( ambientLightColor );
	#if defined( USE_LIGHT_PROBES )
		irradiance += getLightProbeIrradiance( lightProbe, geometryNormal );
	#endif
	#if ( NUM_HEMI_LIGHTS > 0 )
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_HEMI_LIGHTS; i ++ ) {
			irradiance += getHemisphereLightIrradiance( hemisphereLights[ i ], geometryNormal );
		}
		#pragma unroll_loop_end
	#endif
#endif
#if defined( RE_IndirectSpecular )
	vec3 radiance = vec3( 0.0 );
	vec3 clearcoatRadiance = vec3( 0.0 );
#endif`,_M=`#if defined( RE_IndirectDiffuse )
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		vec3 lightMapIrradiance = lightMapTexel.rgb * lightMapIntensity;
		irradiance += lightMapIrradiance;
	#endif
	#if defined( USE_ENVMAP ) && defined( STANDARD ) && defined( ENVMAP_TYPE_CUBE_UV )
		iblIrradiance += getIBLIrradiance( geometryNormal );
	#endif
#endif
#if defined( USE_ENVMAP ) && defined( RE_IndirectSpecular )
	#ifdef USE_ANISOTROPY
		radiance += getIBLAnisotropyRadiance( geometryViewDir, geometryNormal, material.roughness, material.anisotropyB, material.anisotropy );
	#else
		radiance += getIBLRadiance( geometryViewDir, geometryNormal, material.roughness );
	#endif
	#ifdef USE_CLEARCOAT
		clearcoatRadiance += getIBLRadiance( geometryViewDir, geometryClearcoatNormal, material.clearcoatRoughness );
	#endif
#endif`,yM=`#if defined( RE_IndirectDiffuse )
	RE_IndirectDiffuse( irradiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif
#if defined( RE_IndirectSpecular )
	RE_IndirectSpecular( radiance, iblIrradiance, clearcoatRadiance, geometryPosition, geometryNormal, geometryViewDir, geometryClearcoatNormal, material, reflectedLight );
#endif`,MM=`#if defined( USE_LOGARITHMIC_DEPTH_BUFFER )
	gl_FragDepth = vIsPerspective == 0.0 ? gl_FragCoord.z : log2( vFragDepth ) * logDepthBufFC * 0.5;
#endif`,SM=`#if defined( USE_LOGARITHMIC_DEPTH_BUFFER )
	uniform float logDepthBufFC;
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,wM=`#ifdef USE_LOGARITHMIC_DEPTH_BUFFER
	varying float vFragDepth;
	varying float vIsPerspective;
#endif`,bM=`#ifdef USE_LOGARITHMIC_DEPTH_BUFFER
	vFragDepth = 1.0 + gl_Position.w;
	vIsPerspective = float( isPerspectiveMatrix( projectionMatrix ) );
#endif`,EM=`#ifdef USE_MAP
	vec4 sampledDiffuseColor = texture2D( map, vMapUv );
	#ifdef DECODE_VIDEO_TEXTURE
		sampledDiffuseColor = sRGBTransferEOTF( sampledDiffuseColor );
	#endif
	diffuseColor *= sampledDiffuseColor;
#endif`,DM=`#ifdef USE_MAP
	uniform sampler2D map;
#endif`,AM=`#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
	#if defined( USE_POINTS_UV )
		vec2 uv = vUv;
	#else
		vec2 uv = ( uvTransform * vec3( gl_PointCoord.x, 1.0 - gl_PointCoord.y, 1 ) ).xy;
	#endif
#endif
#ifdef USE_MAP
	diffuseColor *= texture2D( map, uv );
#endif
#ifdef USE_ALPHAMAP
	diffuseColor.a *= texture2D( alphaMap, uv ).g;
#endif`,CM=`#if defined( USE_POINTS_UV )
	varying vec2 vUv;
#else
	#if defined( USE_MAP ) || defined( USE_ALPHAMAP )
		uniform mat3 uvTransform;
	#endif
#endif
#ifdef USE_MAP
	uniform sampler2D map;
#endif
#ifdef USE_ALPHAMAP
	uniform sampler2D alphaMap;
#endif`,TM=`float metalnessFactor = metalness;
#ifdef USE_METALNESSMAP
	vec4 texelMetalness = texture2D( metalnessMap, vMetalnessMapUv );
	metalnessFactor *= texelMetalness.b;
#endif`,RM=`#ifdef USE_METALNESSMAP
	uniform sampler2D metalnessMap;
#endif`,FM=`#ifdef USE_INSTANCING_MORPH
	float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	float morphTargetBaseInfluence = texelFetch( morphTexture, ivec2( 0, gl_InstanceID ), 0 ).r;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		morphTargetInfluences[i] =  texelFetch( morphTexture, ivec2( i + 1, gl_InstanceID ), 0 ).r;
	}
#endif`,PM=`#if defined( USE_MORPHCOLORS )
	vColor *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		#if defined( USE_COLOR_ALPHA )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ) * morphTargetInfluences[ i ];
		#elif defined( USE_COLOR )
			if ( morphTargetInfluences[ i ] != 0.0 ) vColor += getMorph( gl_VertexID, i, 2 ).rgb * morphTargetInfluences[ i ];
		#endif
	}
#endif`,IM=`#ifdef USE_MORPHNORMALS
	objectNormal *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) objectNormal += getMorph( gl_VertexID, i, 1 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,NM=`#ifdef USE_MORPHTARGETS
	#ifndef USE_INSTANCING_MORPH
		uniform float morphTargetBaseInfluence;
		uniform float morphTargetInfluences[ MORPHTARGETS_COUNT ];
	#endif
	uniform sampler2DArray morphTargetsTexture;
	uniform ivec2 morphTargetsTextureSize;
	vec4 getMorph( const in int vertexIndex, const in int morphTargetIndex, const in int offset ) {
		int texelIndex = vertexIndex * MORPHTARGETS_TEXTURE_STRIDE + offset;
		int y = texelIndex / morphTargetsTextureSize.x;
		int x = texelIndex - y * morphTargetsTextureSize.x;
		ivec3 morphUV = ivec3( x, y, morphTargetIndex );
		return texelFetch( morphTargetsTexture, morphUV, 0 );
	}
#endif`,LM=`#ifdef USE_MORPHTARGETS
	transformed *= morphTargetBaseInfluence;
	for ( int i = 0; i < MORPHTARGETS_COUNT; i ++ ) {
		if ( morphTargetInfluences[ i ] != 0.0 ) transformed += getMorph( gl_VertexID, i, 0 ).xyz * morphTargetInfluences[ i ];
	}
#endif`,BM=`float faceDirection = gl_FrontFacing ? 1.0 : - 1.0;
#ifdef FLAT_SHADED
	vec3 fdx = dFdx( vViewPosition );
	vec3 fdy = dFdy( vViewPosition );
	vec3 normal = normalize( cross( fdx, fdy ) );
#else
	vec3 normal = normalize( vNormal );
	#ifdef DOUBLE_SIDED
		normal *= faceDirection;
	#endif
#endif
#if defined( USE_NORMALMAP_TANGENTSPACE ) || defined( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY )
	#ifdef USE_TANGENT
		mat3 tbn = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn = getTangentFrame( - vViewPosition, normal,
		#if defined( USE_NORMALMAP )
			vNormalMapUv
		#elif defined( USE_CLEARCOAT_NORMALMAP )
			vClearcoatNormalMapUv
		#else
			vUv
		#endif
		);
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn[0] *= faceDirection;
		tbn[1] *= faceDirection;
	#endif
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	#ifdef USE_TANGENT
		mat3 tbn2 = mat3( normalize( vTangent ), normalize( vBitangent ), normal );
	#else
		mat3 tbn2 = getTangentFrame( - vViewPosition, normal, vClearcoatNormalMapUv );
	#endif
	#if defined( DOUBLE_SIDED ) && ! defined( FLAT_SHADED )
		tbn2[0] *= faceDirection;
		tbn2[1] *= faceDirection;
	#endif
#endif
vec3 nonPerturbedNormal = normal;`,UM=`#ifdef USE_NORMALMAP_OBJECTSPACE
	normal = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	#ifdef FLIP_SIDED
		normal = - normal;
	#endif
	#ifdef DOUBLE_SIDED
		normal = normal * faceDirection;
	#endif
	normal = normalize( normalMatrix * normal );
#elif defined( USE_NORMALMAP_TANGENTSPACE )
	vec3 mapN = texture2D( normalMap, vNormalMapUv ).xyz * 2.0 - 1.0;
	mapN.xy *= normalScale;
	normal = normalize( tbn * mapN );
#elif defined( USE_BUMPMAP )
	normal = perturbNormalArb( - vViewPosition, normal, dHdxy_fwd(), faceDirection );
#endif`,OM=`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,zM=`#ifndef FLAT_SHADED
	varying vec3 vNormal;
	#ifdef USE_TANGENT
		varying vec3 vTangent;
		varying vec3 vBitangent;
	#endif
#endif`,kM=`#ifndef FLAT_SHADED
	vNormal = normalize( transformedNormal );
	#ifdef USE_TANGENT
		vTangent = normalize( transformedTangent );
		vBitangent = normalize( cross( vNormal, vTangent ) * tangent.w );
	#endif
#endif`,VM=`#ifdef USE_NORMALMAP
	uniform sampler2D normalMap;
	uniform vec2 normalScale;
#endif
#ifdef USE_NORMALMAP_OBJECTSPACE
	uniform mat3 normalMatrix;
#endif
#if ! defined ( USE_TANGENT ) && ( defined ( USE_NORMALMAP_TANGENTSPACE ) || defined ( USE_CLEARCOAT_NORMALMAP ) || defined( USE_ANISOTROPY ) )
	mat3 getTangentFrame( vec3 eye_pos, vec3 surf_norm, vec2 uv ) {
		vec3 q0 = dFdx( eye_pos.xyz );
		vec3 q1 = dFdy( eye_pos.xyz );
		vec2 st0 = dFdx( uv.st );
		vec2 st1 = dFdy( uv.st );
		vec3 N = surf_norm;
		vec3 q1perp = cross( q1, N );
		vec3 q0perp = cross( N, q0 );
		vec3 T = q1perp * st0.x + q0perp * st1.x;
		vec3 B = q1perp * st0.y + q0perp * st1.y;
		float det = max( dot( T, T ), dot( B, B ) );
		float scale = ( det == 0.0 ) ? 0.0 : inversesqrt( det );
		return mat3( T * scale, B * scale, N );
	}
#endif`,HM=`#ifdef USE_CLEARCOAT
	vec3 clearcoatNormal = nonPerturbedNormal;
#endif`,GM=`#ifdef USE_CLEARCOAT_NORMALMAP
	vec3 clearcoatMapN = texture2D( clearcoatNormalMap, vClearcoatNormalMapUv ).xyz * 2.0 - 1.0;
	clearcoatMapN.xy *= clearcoatNormalScale;
	clearcoatNormal = normalize( tbn2 * clearcoatMapN );
#endif`,WM=`#ifdef USE_CLEARCOATMAP
	uniform sampler2D clearcoatMap;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform sampler2D clearcoatNormalMap;
	uniform vec2 clearcoatNormalScale;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform sampler2D clearcoatRoughnessMap;
#endif`,qM=`#ifdef USE_IRIDESCENCEMAP
	uniform sampler2D iridescenceMap;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform sampler2D iridescenceThicknessMap;
#endif`,XM=`#ifdef OPAQUE
diffuseColor.a = 1.0;
#endif
#ifdef USE_TRANSMISSION
diffuseColor.a *= material.transmissionAlpha;
#endif
gl_FragColor = vec4( outgoingLight, diffuseColor.a );`,YM=`vec3 packNormalToRGB( const in vec3 normal ) {
	return normalize( normal ) * 0.5 + 0.5;
}
vec3 unpackRGBToNormal( const in vec3 rgb ) {
	return 2.0 * rgb.xyz - 1.0;
}
const float PackUpscale = 256. / 255.;const float UnpackDownscale = 255. / 256.;const float ShiftRight8 = 1. / 256.;
const float Inv255 = 1. / 255.;
const vec4 PackFactors = vec4( 1.0, 256.0, 256.0 * 256.0, 256.0 * 256.0 * 256.0 );
const vec2 UnpackFactors2 = vec2( UnpackDownscale, 1.0 / PackFactors.g );
const vec3 UnpackFactors3 = vec3( UnpackDownscale / PackFactors.rg, 1.0 / PackFactors.b );
const vec4 UnpackFactors4 = vec4( UnpackDownscale / PackFactors.rgb, 1.0 / PackFactors.a );
vec4 packDepthToRGBA( const in float v ) {
	if( v <= 0.0 )
		return vec4( 0., 0., 0., 0. );
	if( v >= 1.0 )
		return vec4( 1., 1., 1., 1. );
	float vuf;
	float af = modf( v * PackFactors.a, vuf );
	float bf = modf( vuf * ShiftRight8, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec4( vuf * Inv255, gf * PackUpscale, bf * PackUpscale, af );
}
vec3 packDepthToRGB( const in float v ) {
	if( v <= 0.0 )
		return vec3( 0., 0., 0. );
	if( v >= 1.0 )
		return vec3( 1., 1., 1. );
	float vuf;
	float bf = modf( v * PackFactors.b, vuf );
	float gf = modf( vuf * ShiftRight8, vuf );
	return vec3( vuf * Inv255, gf * PackUpscale, bf );
}
vec2 packDepthToRG( const in float v ) {
	if( v <= 0.0 )
		return vec2( 0., 0. );
	if( v >= 1.0 )
		return vec2( 1., 1. );
	float vuf;
	float gf = modf( v * 256., vuf );
	return vec2( vuf * Inv255, gf );
}
float unpackRGBAToDepth( const in vec4 v ) {
	return dot( v, UnpackFactors4 );
}
float unpackRGBToDepth( const in vec3 v ) {
	return dot( v, UnpackFactors3 );
}
float unpackRGToDepth( const in vec2 v ) {
	return v.r * UnpackFactors2.r + v.g * UnpackFactors2.g;
}
vec4 pack2HalfToRGBA( const in vec2 v ) {
	vec4 r = vec4( v.x, fract( v.x * 255.0 ), v.y, fract( v.y * 255.0 ) );
	return vec4( r.x - r.y / 255.0, r.y, r.z - r.w / 255.0, r.w );
}
vec2 unpackRGBATo2Half( const in vec4 v ) {
	return vec2( v.x + ( v.y / 255.0 ), v.z + ( v.w / 255.0 ) );
}
float viewZToOrthographicDepth( const in float viewZ, const in float near, const in float far ) {
	return ( viewZ + near ) / ( near - far );
}
float orthographicDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return depth * ( near - far ) - near;
}
float viewZToPerspectiveDepth( const in float viewZ, const in float near, const in float far ) {
	return ( ( near + viewZ ) * far ) / ( ( far - near ) * viewZ );
}
float perspectiveDepthToViewZ( const in float depth, const in float near, const in float far ) {
	return ( near * far ) / ( ( far - near ) * depth - far );
}`,ZM=`#ifdef PREMULTIPLIED_ALPHA
	gl_FragColor.rgb *= gl_FragColor.a;
#endif`,$M=`vec4 mvPosition = vec4( transformed, 1.0 );
#ifdef USE_BATCHING
	mvPosition = batchingMatrix * mvPosition;
#endif
#ifdef USE_INSTANCING
	mvPosition = instanceMatrix * mvPosition;
#endif
mvPosition = modelViewMatrix * mvPosition;
gl_Position = projectionMatrix * mvPosition;`,JM=`#ifdef DITHERING
	gl_FragColor.rgb = dithering( gl_FragColor.rgb );
#endif`,KM=`#ifdef DITHERING
	vec3 dithering( vec3 color ) {
		float grid_position = rand( gl_FragCoord.xy );
		vec3 dither_shift_RGB = vec3( 0.25 / 255.0, -0.25 / 255.0, 0.25 / 255.0 );
		dither_shift_RGB = mix( 2.0 * dither_shift_RGB, -2.0 * dither_shift_RGB, grid_position );
		return color + dither_shift_RGB;
	}
#endif`,QM=`float roughnessFactor = roughness;
#ifdef USE_ROUGHNESSMAP
	vec4 texelRoughness = texture2D( roughnessMap, vRoughnessMapUv );
	roughnessFactor *= texelRoughness.g;
#endif`,jM=`#ifdef USE_ROUGHNESSMAP
	uniform sampler2D roughnessMap;
#endif`,eS=`#if NUM_SPOT_LIGHT_COORDS > 0
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#if NUM_SPOT_LIGHT_MAPS > 0
	uniform sampler2D spotLightMap[ NUM_SPOT_LIGHT_MAPS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform sampler2D directionalShadowMap[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		uniform sampler2D spotShadowMap[ NUM_SPOT_LIGHT_SHADOWS ];
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform sampler2D pointShadowMap[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
	float texture2DCompare( sampler2D depths, vec2 uv, float compare ) {
		float depth = unpackRGBAToDepth( texture2D( depths, uv ) );
		#ifdef USE_REVERSED_DEPTH_BUFFER
			return step( depth, compare );
		#else
			return step( compare, depth );
		#endif
	}
	vec2 texture2DDistribution( sampler2D shadow, vec2 uv ) {
		return unpackRGBATo2Half( texture2D( shadow, uv ) );
	}
	float VSMShadow( sampler2D shadow, vec2 uv, float compare ) {
		float occlusion = 1.0;
		vec2 distribution = texture2DDistribution( shadow, uv );
		#ifdef USE_REVERSED_DEPTH_BUFFER
			float hard_shadow = step( distribution.x, compare );
		#else
			float hard_shadow = step( compare, distribution.x );
		#endif
		if ( hard_shadow != 1.0 ) {
			float distance = compare - distribution.x;
			float variance = max( 0.00000, distribution.y * distribution.y );
			float softness_probability = variance / (variance + distance * distance );			softness_probability = clamp( ( softness_probability - 0.3 ) / ( 0.95 - 0.3 ), 0.0, 1.0 );			occlusion = clamp( max( hard_shadow, softness_probability ), 0.0, 1.0 );
		}
		return occlusion;
	}
	float getShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord ) {
		float shadow = 1.0;
		shadowCoord.xyz /= shadowCoord.w;
		shadowCoord.z += shadowBias;
		bool inFrustum = shadowCoord.x >= 0.0 && shadowCoord.x <= 1.0 && shadowCoord.y >= 0.0 && shadowCoord.y <= 1.0;
		bool frustumTest = inFrustum && shadowCoord.z <= 1.0;
		if ( frustumTest ) {
		#if defined( SHADOWMAP_TYPE_PCF )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx0 = - texelSize.x * shadowRadius;
			float dy0 = - texelSize.y * shadowRadius;
			float dx1 = + texelSize.x * shadowRadius;
			float dy1 = + texelSize.y * shadowRadius;
			float dx2 = dx0 / 2.0;
			float dy2 = dy0 / 2.0;
			float dx3 = dx1 / 2.0;
			float dy3 = dy1 / 2.0;
			shadow = (
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy2 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx2, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx3, dy3 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( 0.0, dy1 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, shadowCoord.xy + vec2( dx1, dy1 ), shadowCoord.z )
			) * ( 1.0 / 17.0 );
		#elif defined( SHADOWMAP_TYPE_PCF_SOFT )
			vec2 texelSize = vec2( 1.0 ) / shadowMapSize;
			float dx = texelSize.x;
			float dy = texelSize.y;
			vec2 uv = shadowCoord.xy;
			vec2 f = fract( uv * shadowMapSize + 0.5 );
			uv -= f * texelSize;
			shadow = (
				texture2DCompare( shadowMap, uv, shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( dx, 0.0 ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + vec2( 0.0, dy ), shadowCoord.z ) +
				texture2DCompare( shadowMap, uv + texelSize, shadowCoord.z ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, 0.0 ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 0.0 ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( -dx, dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, dy ), shadowCoord.z ),
					 f.x ) +
				mix( texture2DCompare( shadowMap, uv + vec2( 0.0, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( 0.0, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( texture2DCompare( shadowMap, uv + vec2( dx, -dy ), shadowCoord.z ),
					 texture2DCompare( shadowMap, uv + vec2( dx, 2.0 * dy ), shadowCoord.z ),
					 f.y ) +
				mix( mix( texture2DCompare( shadowMap, uv + vec2( -dx, -dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, -dy ), shadowCoord.z ),
						  f.x ),
					 mix( texture2DCompare( shadowMap, uv + vec2( -dx, 2.0 * dy ), shadowCoord.z ),
						  texture2DCompare( shadowMap, uv + vec2( 2.0 * dx, 2.0 * dy ), shadowCoord.z ),
						  f.x ),
					 f.y )
			) * ( 1.0 / 9.0 );
		#elif defined( SHADOWMAP_TYPE_VSM )
			shadow = VSMShadow( shadowMap, shadowCoord.xy, shadowCoord.z );
		#else
			shadow = texture2DCompare( shadowMap, shadowCoord.xy, shadowCoord.z );
		#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
	vec2 cubeToUV( vec3 v, float texelSizeY ) {
		vec3 absV = abs( v );
		float scaleToCube = 1.0 / max( absV.x, max( absV.y, absV.z ) );
		absV *= scaleToCube;
		v *= scaleToCube * ( 1.0 - 2.0 * texelSizeY );
		vec2 planar = v.xy;
		float almostATexel = 1.5 * texelSizeY;
		float almostOne = 1.0 - almostATexel;
		if ( absV.z >= almostOne ) {
			if ( v.z > 0.0 )
				planar.x = 4.0 - v.x;
		} else if ( absV.x >= almostOne ) {
			float signX = sign( v.x );
			planar.x = v.z * signX + 2.0 * signX;
		} else if ( absV.y >= almostOne ) {
			float signY = sign( v.y );
			planar.x = v.x + 2.0 * signY + 2.0;
			planar.y = v.z * signY - 2.0;
		}
		return vec2( 0.125, 0.25 ) * planar + vec2( 0.375, 0.75 );
	}
	float getPointShadow( sampler2D shadowMap, vec2 shadowMapSize, float shadowIntensity, float shadowBias, float shadowRadius, vec4 shadowCoord, float shadowCameraNear, float shadowCameraFar ) {
		float shadow = 1.0;
		vec3 lightToPosition = shadowCoord.xyz;
		
		float lightToPositionLength = length( lightToPosition );
		if ( lightToPositionLength - shadowCameraFar <= 0.0 && lightToPositionLength - shadowCameraNear >= 0.0 ) {
			float dp = ( lightToPositionLength - shadowCameraNear ) / ( shadowCameraFar - shadowCameraNear );			dp += shadowBias;
			vec3 bd3D = normalize( lightToPosition );
			vec2 texelSize = vec2( 1.0 ) / ( shadowMapSize * vec2( 4.0, 2.0 ) );
			#if defined( SHADOWMAP_TYPE_PCF ) || defined( SHADOWMAP_TYPE_PCF_SOFT ) || defined( SHADOWMAP_TYPE_VSM )
				vec2 offset = vec2( - 1, 1 ) * shadowRadius * texelSize.y;
				shadow = (
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yyx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxy, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.xxx, texelSize.y ), dp ) +
					texture2DCompare( shadowMap, cubeToUV( bd3D + offset.yxx, texelSize.y ), dp )
				) * ( 1.0 / 9.0 );
			#else
				shadow = texture2DCompare( shadowMap, cubeToUV( bd3D, texelSize.y ), dp );
			#endif
		}
		return mix( 1.0, shadow, shadowIntensity );
	}
#endif`,tS=`#if NUM_SPOT_LIGHT_COORDS > 0
	uniform mat4 spotLightMatrix[ NUM_SPOT_LIGHT_COORDS ];
	varying vec4 vSpotLightCoord[ NUM_SPOT_LIGHT_COORDS ];
#endif
#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
		uniform mat4 directionalShadowMatrix[ NUM_DIR_LIGHT_SHADOWS ];
		varying vec4 vDirectionalShadowCoord[ NUM_DIR_LIGHT_SHADOWS ];
		struct DirectionalLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform DirectionalLightShadow directionalLightShadows[ NUM_DIR_LIGHT_SHADOWS ];
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
		struct SpotLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
		};
		uniform SpotLightShadow spotLightShadows[ NUM_SPOT_LIGHT_SHADOWS ];
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		uniform mat4 pointShadowMatrix[ NUM_POINT_LIGHT_SHADOWS ];
		varying vec4 vPointShadowCoord[ NUM_POINT_LIGHT_SHADOWS ];
		struct PointLightShadow {
			float shadowIntensity;
			float shadowBias;
			float shadowNormalBias;
			float shadowRadius;
			vec2 shadowMapSize;
			float shadowCameraNear;
			float shadowCameraFar;
		};
		uniform PointLightShadow pointLightShadows[ NUM_POINT_LIGHT_SHADOWS ];
	#endif
#endif`,nS=`#if ( defined( USE_SHADOWMAP ) && ( NUM_DIR_LIGHT_SHADOWS > 0 || NUM_POINT_LIGHT_SHADOWS > 0 ) ) || ( NUM_SPOT_LIGHT_COORDS > 0 )
	vec3 shadowWorldNormal = inverseTransformDirection( transformedNormal, viewMatrix );
	vec4 shadowWorldPosition;
#endif
#if defined( USE_SHADOWMAP )
	#if NUM_DIR_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * directionalLightShadows[ i ].shadowNormalBias, 0 );
			vDirectionalShadowCoord[ i ] = directionalShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
		#pragma unroll_loop_start
		for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
			shadowWorldPosition = worldPosition + vec4( shadowWorldNormal * pointLightShadows[ i ].shadowNormalBias, 0 );
			vPointShadowCoord[ i ] = pointShadowMatrix[ i ] * shadowWorldPosition;
		}
		#pragma unroll_loop_end
	#endif
#endif
#if NUM_SPOT_LIGHT_COORDS > 0
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_COORDS; i ++ ) {
		shadowWorldPosition = worldPosition;
		#if ( defined( USE_SHADOWMAP ) && UNROLLED_LOOP_INDEX < NUM_SPOT_LIGHT_SHADOWS )
			shadowWorldPosition.xyz += shadowWorldNormal * spotLightShadows[ i ].shadowNormalBias;
		#endif
		vSpotLightCoord[ i ] = spotLightMatrix[ i ] * shadowWorldPosition;
	}
	#pragma unroll_loop_end
#endif`,rS=`float getShadowMask() {
	float shadow = 1.0;
	#ifdef USE_SHADOWMAP
	#if NUM_DIR_LIGHT_SHADOWS > 0
	DirectionalLightShadow directionalLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_DIR_LIGHT_SHADOWS; i ++ ) {
		directionalLight = directionalLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( directionalShadowMap[ i ], directionalLight.shadowMapSize, directionalLight.shadowIntensity, directionalLight.shadowBias, directionalLight.shadowRadius, vDirectionalShadowCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_SPOT_LIGHT_SHADOWS > 0
	SpotLightShadow spotLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_SPOT_LIGHT_SHADOWS; i ++ ) {
		spotLight = spotLightShadows[ i ];
		shadow *= receiveShadow ? getShadow( spotShadowMap[ i ], spotLight.shadowMapSize, spotLight.shadowIntensity, spotLight.shadowBias, spotLight.shadowRadius, vSpotLightCoord[ i ] ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#if NUM_POINT_LIGHT_SHADOWS > 0
	PointLightShadow pointLight;
	#pragma unroll_loop_start
	for ( int i = 0; i < NUM_POINT_LIGHT_SHADOWS; i ++ ) {
		pointLight = pointLightShadows[ i ];
		shadow *= receiveShadow ? getPointShadow( pointShadowMap[ i ], pointLight.shadowMapSize, pointLight.shadowIntensity, pointLight.shadowBias, pointLight.shadowRadius, vPointShadowCoord[ i ], pointLight.shadowCameraNear, pointLight.shadowCameraFar ) : 1.0;
	}
	#pragma unroll_loop_end
	#endif
	#endif
	return shadow;
}`,iS=`#ifdef USE_SKINNING
	mat4 boneMatX = getBoneMatrix( skinIndex.x );
	mat4 boneMatY = getBoneMatrix( skinIndex.y );
	mat4 boneMatZ = getBoneMatrix( skinIndex.z );
	mat4 boneMatW = getBoneMatrix( skinIndex.w );
#endif`,oS=`#ifdef USE_SKINNING
	uniform mat4 bindMatrix;
	uniform mat4 bindMatrixInverse;
	uniform highp sampler2D boneTexture;
	mat4 getBoneMatrix( const in float i ) {
		int size = textureSize( boneTexture, 0 ).x;
		int j = int( i ) * 4;
		int x = j % size;
		int y = j / size;
		vec4 v1 = texelFetch( boneTexture, ivec2( x, y ), 0 );
		vec4 v2 = texelFetch( boneTexture, ivec2( x + 1, y ), 0 );
		vec4 v3 = texelFetch( boneTexture, ivec2( x + 2, y ), 0 );
		vec4 v4 = texelFetch( boneTexture, ivec2( x + 3, y ), 0 );
		return mat4( v1, v2, v3, v4 );
	}
#endif`,sS=`#ifdef USE_SKINNING
	vec4 skinVertex = bindMatrix * vec4( transformed, 1.0 );
	vec4 skinned = vec4( 0.0 );
	skinned += boneMatX * skinVertex * skinWeight.x;
	skinned += boneMatY * skinVertex * skinWeight.y;
	skinned += boneMatZ * skinVertex * skinWeight.z;
	skinned += boneMatW * skinVertex * skinWeight.w;
	transformed = ( bindMatrixInverse * skinned ).xyz;
#endif`,aS=`#ifdef USE_SKINNING
	mat4 skinMatrix = mat4( 0.0 );
	skinMatrix += skinWeight.x * boneMatX;
	skinMatrix += skinWeight.y * boneMatY;
	skinMatrix += skinWeight.z * boneMatZ;
	skinMatrix += skinWeight.w * boneMatW;
	skinMatrix = bindMatrixInverse * skinMatrix * bindMatrix;
	objectNormal = vec4( skinMatrix * vec4( objectNormal, 0.0 ) ).xyz;
	#ifdef USE_TANGENT
		objectTangent = vec4( skinMatrix * vec4( objectTangent, 0.0 ) ).xyz;
	#endif
#endif`,uS=`float specularStrength;
#ifdef USE_SPECULARMAP
	vec4 texelSpecular = texture2D( specularMap, vSpecularMapUv );
	specularStrength = texelSpecular.r;
#else
	specularStrength = 1.0;
#endif`,lS=`#ifdef USE_SPECULARMAP
	uniform sampler2D specularMap;
#endif`,cS=`#if defined( TONE_MAPPING )
	gl_FragColor.rgb = toneMapping( gl_FragColor.rgb );
#endif`,fS=`#ifndef saturate
#define saturate( a ) clamp( a, 0.0, 1.0 )
#endif
uniform float toneMappingExposure;
vec3 LinearToneMapping( vec3 color ) {
	return saturate( toneMappingExposure * color );
}
vec3 ReinhardToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	return saturate( color / ( vec3( 1.0 ) + color ) );
}
vec3 CineonToneMapping( vec3 color ) {
	color *= toneMappingExposure;
	color = max( vec3( 0.0 ), color - 0.004 );
	return pow( ( color * ( 6.2 * color + 0.5 ) ) / ( color * ( 6.2 * color + 1.7 ) + 0.06 ), vec3( 2.2 ) );
}
vec3 RRTAndODTFit( vec3 v ) {
	vec3 a = v * ( v + 0.0245786 ) - 0.000090537;
	vec3 b = v * ( 0.983729 * v + 0.4329510 ) + 0.238081;
	return a / b;
}
vec3 ACESFilmicToneMapping( vec3 color ) {
	const mat3 ACESInputMat = mat3(
		vec3( 0.59719, 0.07600, 0.02840 ),		vec3( 0.35458, 0.90834, 0.13383 ),
		vec3( 0.04823, 0.01566, 0.83777 )
	);
	const mat3 ACESOutputMat = mat3(
		vec3(  1.60475, -0.10208, -0.00327 ),		vec3( -0.53108,  1.10813, -0.07276 ),
		vec3( -0.07367, -0.00605,  1.07602 )
	);
	color *= toneMappingExposure / 0.6;
	color = ACESInputMat * color;
	color = RRTAndODTFit( color );
	color = ACESOutputMat * color;
	return saturate( color );
}
const mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3(
	vec3( 1.6605, - 0.1246, - 0.0182 ),
	vec3( - 0.5876, 1.1329, - 0.1006 ),
	vec3( - 0.0728, - 0.0083, 1.1187 )
);
const mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3(
	vec3( 0.6274, 0.0691, 0.0164 ),
	vec3( 0.3293, 0.9195, 0.0880 ),
	vec3( 0.0433, 0.0113, 0.8956 )
);
vec3 agxDefaultContrastApprox( vec3 x ) {
	vec3 x2 = x * x;
	vec3 x4 = x2 * x2;
	return + 15.5 * x4 * x2
		- 40.14 * x4 * x
		+ 31.96 * x4
		- 6.868 * x2 * x
		+ 0.4298 * x2
		+ 0.1191 * x
		- 0.00232;
}
vec3 AgXToneMapping( vec3 color ) {
	const mat3 AgXInsetMatrix = mat3(
		vec3( 0.856627153315983, 0.137318972929847, 0.11189821299995 ),
		vec3( 0.0951212405381588, 0.761241990602591, 0.0767994186031903 ),
		vec3( 0.0482516061458583, 0.101439036467562, 0.811302368396859 )
	);
	const mat3 AgXOutsetMatrix = mat3(
		vec3( 1.1271005818144368, - 0.1413297634984383, - 0.14132976349843826 ),
		vec3( - 0.11060664309660323, 1.157823702216272, - 0.11060664309660294 ),
		vec3( - 0.016493938717834573, - 0.016493938717834257, 1.2519364065950405 )
	);
	const float AgxMinEv = - 12.47393;	const float AgxMaxEv = 4.026069;
	color *= toneMappingExposure;
	color = LINEAR_SRGB_TO_LINEAR_REC2020 * color;
	color = AgXInsetMatrix * color;
	color = max( color, 1e-10 );	color = log2( color );
	color = ( color - AgxMinEv ) / ( AgxMaxEv - AgxMinEv );
	color = clamp( color, 0.0, 1.0 );
	color = agxDefaultContrastApprox( color );
	color = AgXOutsetMatrix * color;
	color = pow( max( vec3( 0.0 ), color ), vec3( 2.2 ) );
	color = LINEAR_REC2020_TO_LINEAR_SRGB * color;
	color = clamp( color, 0.0, 1.0 );
	return color;
}
vec3 NeutralToneMapping( vec3 color ) {
	const float StartCompression = 0.8 - 0.04;
	const float Desaturation = 0.15;
	color *= toneMappingExposure;
	float x = min( color.r, min( color.g, color.b ) );
	float offset = x < 0.08 ? x - 6.25 * x * x : 0.04;
	color -= offset;
	float peak = max( color.r, max( color.g, color.b ) );
	if ( peak < StartCompression ) return color;
	float d = 1. - StartCompression;
	float newPeak = 1. - d * d / ( peak + d - StartCompression );
	color *= newPeak / peak;
	float g = 1. - 1. / ( Desaturation * ( peak - newPeak ) + 1. );
	return mix( color, vec3( newPeak ), g );
}
vec3 CustomToneMapping( vec3 color ) { return color; }`,hS=`#ifdef USE_TRANSMISSION
	material.transmission = transmission;
	material.transmissionAlpha = 1.0;
	material.thickness = thickness;
	material.attenuationDistance = attenuationDistance;
	material.attenuationColor = attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		material.transmission *= texture2D( transmissionMap, vTransmissionMapUv ).r;
	#endif
	#ifdef USE_THICKNESSMAP
		material.thickness *= texture2D( thicknessMap, vThicknessMapUv ).g;
	#endif
	vec3 pos = vWorldPosition;
	vec3 v = normalize( cameraPosition - pos );
	vec3 n = inverseTransformDirection( normal, viewMatrix );
	vec4 transmitted = getIBLVolumeRefraction(
		n, v, material.roughness, material.diffuseColor, material.specularColor, material.specularF90,
		pos, modelMatrix, viewMatrix, projectionMatrix, material.dispersion, material.ior, material.thickness,
		material.attenuationColor, material.attenuationDistance );
	material.transmissionAlpha = mix( material.transmissionAlpha, transmitted.a, material.transmission );
	totalDiffuse = mix( totalDiffuse, transmitted.rgb, material.transmission );
#endif`,dS=`#ifdef USE_TRANSMISSION
	uniform float transmission;
	uniform float thickness;
	uniform float attenuationDistance;
	uniform vec3 attenuationColor;
	#ifdef USE_TRANSMISSIONMAP
		uniform sampler2D transmissionMap;
	#endif
	#ifdef USE_THICKNESSMAP
		uniform sampler2D thicknessMap;
	#endif
	uniform vec2 transmissionSamplerSize;
	uniform sampler2D transmissionSamplerMap;
	uniform mat4 modelMatrix;
	uniform mat4 projectionMatrix;
	varying vec3 vWorldPosition;
	float w0( float a ) {
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - a + 3.0 ) - 3.0 ) + 1.0 );
	}
	float w1( float a ) {
		return ( 1.0 / 6.0 ) * ( a *  a * ( 3.0 * a - 6.0 ) + 4.0 );
	}
	float w2( float a ){
		return ( 1.0 / 6.0 ) * ( a * ( a * ( - 3.0 * a + 3.0 ) + 3.0 ) + 1.0 );
	}
	float w3( float a ) {
		return ( 1.0 / 6.0 ) * ( a * a * a );
	}
	float g0( float a ) {
		return w0( a ) + w1( a );
	}
	float g1( float a ) {
		return w2( a ) + w3( a );
	}
	float h0( float a ) {
		return - 1.0 + w1( a ) / ( w0( a ) + w1( a ) );
	}
	float h1( float a ) {
		return 1.0 + w3( a ) / ( w2( a ) + w3( a ) );
	}
	vec4 bicubic( sampler2D tex, vec2 uv, vec4 texelSize, float lod ) {
		uv = uv * texelSize.zw + 0.5;
		vec2 iuv = floor( uv );
		vec2 fuv = fract( uv );
		float g0x = g0( fuv.x );
		float g1x = g1( fuv.x );
		float h0x = h0( fuv.x );
		float h1x = h1( fuv.x );
		float h0y = h0( fuv.y );
		float h1y = h1( fuv.y );
		vec2 p0 = ( vec2( iuv.x + h0x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p1 = ( vec2( iuv.x + h1x, iuv.y + h0y ) - 0.5 ) * texelSize.xy;
		vec2 p2 = ( vec2( iuv.x + h0x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		vec2 p3 = ( vec2( iuv.x + h1x, iuv.y + h1y ) - 0.5 ) * texelSize.xy;
		return g0( fuv.y ) * ( g0x * textureLod( tex, p0, lod ) + g1x * textureLod( tex, p1, lod ) ) +
			g1( fuv.y ) * ( g0x * textureLod( tex, p2, lod ) + g1x * textureLod( tex, p3, lod ) );
	}
	vec4 textureBicubic( sampler2D sampler, vec2 uv, float lod ) {
		vec2 fLodSize = vec2( textureSize( sampler, int( lod ) ) );
		vec2 cLodSize = vec2( textureSize( sampler, int( lod + 1.0 ) ) );
		vec2 fLodSizeInv = 1.0 / fLodSize;
		vec2 cLodSizeInv = 1.0 / cLodSize;
		vec4 fSample = bicubic( sampler, uv, vec4( fLodSizeInv, fLodSize ), floor( lod ) );
		vec4 cSample = bicubic( sampler, uv, vec4( cLodSizeInv, cLodSize ), ceil( lod ) );
		return mix( fSample, cSample, fract( lod ) );
	}
	vec3 getVolumeTransmissionRay( const in vec3 n, const in vec3 v, const in float thickness, const in float ior, const in mat4 modelMatrix ) {
		vec3 refractionVector = refract( - v, normalize( n ), 1.0 / ior );
		vec3 modelScale;
		modelScale.x = length( vec3( modelMatrix[ 0 ].xyz ) );
		modelScale.y = length( vec3( modelMatrix[ 1 ].xyz ) );
		modelScale.z = length( vec3( modelMatrix[ 2 ].xyz ) );
		return normalize( refractionVector ) * thickness * modelScale;
	}
	float applyIorToRoughness( const in float roughness, const in float ior ) {
		return roughness * clamp( ior * 2.0 - 2.0, 0.0, 1.0 );
	}
	vec4 getTransmissionSample( const in vec2 fragCoord, const in float roughness, const in float ior ) {
		float lod = log2( transmissionSamplerSize.x ) * applyIorToRoughness( roughness, ior );
		return textureBicubic( transmissionSamplerMap, fragCoord.xy, lod );
	}
	vec3 volumeAttenuation( const in float transmissionDistance, const in vec3 attenuationColor, const in float attenuationDistance ) {
		if ( isinf( attenuationDistance ) ) {
			return vec3( 1.0 );
		} else {
			vec3 attenuationCoefficient = -log( attenuationColor ) / attenuationDistance;
			vec3 transmittance = exp( - attenuationCoefficient * transmissionDistance );			return transmittance;
		}
	}
	vec4 getIBLVolumeRefraction( const in vec3 n, const in vec3 v, const in float roughness, const in vec3 diffuseColor,
		const in vec3 specularColor, const in float specularF90, const in vec3 position, const in mat4 modelMatrix,
		const in mat4 viewMatrix, const in mat4 projMatrix, const in float dispersion, const in float ior, const in float thickness,
		const in vec3 attenuationColor, const in float attenuationDistance ) {
		vec4 transmittedLight;
		vec3 transmittance;
		#ifdef USE_DISPERSION
			float halfSpread = ( ior - 1.0 ) * 0.025 * dispersion;
			vec3 iors = vec3( ior - halfSpread, ior, ior + halfSpread );
			for ( int i = 0; i < 3; i ++ ) {
				vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, iors[ i ], modelMatrix );
				vec3 refractedRayExit = position + transmissionRay;
				vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
				vec2 refractionCoords = ndcPos.xy / ndcPos.w;
				refractionCoords += 1.0;
				refractionCoords /= 2.0;
				vec4 transmissionSample = getTransmissionSample( refractionCoords, roughness, iors[ i ] );
				transmittedLight[ i ] = transmissionSample[ i ];
				transmittedLight.a += transmissionSample.a;
				transmittance[ i ] = diffuseColor[ i ] * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance )[ i ];
			}
			transmittedLight.a /= 3.0;
		#else
			vec3 transmissionRay = getVolumeTransmissionRay( n, v, thickness, ior, modelMatrix );
			vec3 refractedRayExit = position + transmissionRay;
			vec4 ndcPos = projMatrix * viewMatrix * vec4( refractedRayExit, 1.0 );
			vec2 refractionCoords = ndcPos.xy / ndcPos.w;
			refractionCoords += 1.0;
			refractionCoords /= 2.0;
			transmittedLight = getTransmissionSample( refractionCoords, roughness, ior );
			transmittance = diffuseColor * volumeAttenuation( length( transmissionRay ), attenuationColor, attenuationDistance );
		#endif
		vec3 attenuatedColor = transmittance * transmittedLight.rgb;
		vec3 F = EnvironmentBRDF( n, v, specularColor, specularF90, roughness );
		float transmittanceFactor = ( transmittance.r + transmittance.g + transmittance.b ) / 3.0;
		return vec4( ( 1.0 - F ) * attenuatedColor, 1.0 - ( 1.0 - transmittedLight.a ) * transmittanceFactor );
	}
#endif`,pS=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_SPECULARMAP
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,mS=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	varying vec2 vUv;
#endif
#ifdef USE_MAP
	uniform mat3 mapTransform;
	varying vec2 vMapUv;
#endif
#ifdef USE_ALPHAMAP
	uniform mat3 alphaMapTransform;
	varying vec2 vAlphaMapUv;
#endif
#ifdef USE_LIGHTMAP
	uniform mat3 lightMapTransform;
	varying vec2 vLightMapUv;
#endif
#ifdef USE_AOMAP
	uniform mat3 aoMapTransform;
	varying vec2 vAoMapUv;
#endif
#ifdef USE_BUMPMAP
	uniform mat3 bumpMapTransform;
	varying vec2 vBumpMapUv;
#endif
#ifdef USE_NORMALMAP
	uniform mat3 normalMapTransform;
	varying vec2 vNormalMapUv;
#endif
#ifdef USE_DISPLACEMENTMAP
	uniform mat3 displacementMapTransform;
	varying vec2 vDisplacementMapUv;
#endif
#ifdef USE_EMISSIVEMAP
	uniform mat3 emissiveMapTransform;
	varying vec2 vEmissiveMapUv;
#endif
#ifdef USE_METALNESSMAP
	uniform mat3 metalnessMapTransform;
	varying vec2 vMetalnessMapUv;
#endif
#ifdef USE_ROUGHNESSMAP
	uniform mat3 roughnessMapTransform;
	varying vec2 vRoughnessMapUv;
#endif
#ifdef USE_ANISOTROPYMAP
	uniform mat3 anisotropyMapTransform;
	varying vec2 vAnisotropyMapUv;
#endif
#ifdef USE_CLEARCOATMAP
	uniform mat3 clearcoatMapTransform;
	varying vec2 vClearcoatMapUv;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	uniform mat3 clearcoatNormalMapTransform;
	varying vec2 vClearcoatNormalMapUv;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	uniform mat3 clearcoatRoughnessMapTransform;
	varying vec2 vClearcoatRoughnessMapUv;
#endif
#ifdef USE_SHEEN_COLORMAP
	uniform mat3 sheenColorMapTransform;
	varying vec2 vSheenColorMapUv;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	uniform mat3 sheenRoughnessMapTransform;
	varying vec2 vSheenRoughnessMapUv;
#endif
#ifdef USE_IRIDESCENCEMAP
	uniform mat3 iridescenceMapTransform;
	varying vec2 vIridescenceMapUv;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	uniform mat3 iridescenceThicknessMapTransform;
	varying vec2 vIridescenceThicknessMapUv;
#endif
#ifdef USE_SPECULARMAP
	uniform mat3 specularMapTransform;
	varying vec2 vSpecularMapUv;
#endif
#ifdef USE_SPECULAR_COLORMAP
	uniform mat3 specularColorMapTransform;
	varying vec2 vSpecularColorMapUv;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	uniform mat3 specularIntensityMapTransform;
	varying vec2 vSpecularIntensityMapUv;
#endif
#ifdef USE_TRANSMISSIONMAP
	uniform mat3 transmissionMapTransform;
	varying vec2 vTransmissionMapUv;
#endif
#ifdef USE_THICKNESSMAP
	uniform mat3 thicknessMapTransform;
	varying vec2 vThicknessMapUv;
#endif`,gS=`#if defined( USE_UV ) || defined( USE_ANISOTROPY )
	vUv = vec3( uv, 1 ).xy;
#endif
#ifdef USE_MAP
	vMapUv = ( mapTransform * vec3( MAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ALPHAMAP
	vAlphaMapUv = ( alphaMapTransform * vec3( ALPHAMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_LIGHTMAP
	vLightMapUv = ( lightMapTransform * vec3( LIGHTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_AOMAP
	vAoMapUv = ( aoMapTransform * vec3( AOMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_BUMPMAP
	vBumpMapUv = ( bumpMapTransform * vec3( BUMPMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_NORMALMAP
	vNormalMapUv = ( normalMapTransform * vec3( NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_DISPLACEMENTMAP
	vDisplacementMapUv = ( displacementMapTransform * vec3( DISPLACEMENTMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_EMISSIVEMAP
	vEmissiveMapUv = ( emissiveMapTransform * vec3( EMISSIVEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_METALNESSMAP
	vMetalnessMapUv = ( metalnessMapTransform * vec3( METALNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ROUGHNESSMAP
	vRoughnessMapUv = ( roughnessMapTransform * vec3( ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_ANISOTROPYMAP
	vAnisotropyMapUv = ( anisotropyMapTransform * vec3( ANISOTROPYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOATMAP
	vClearcoatMapUv = ( clearcoatMapTransform * vec3( CLEARCOATMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_NORMALMAP
	vClearcoatNormalMapUv = ( clearcoatNormalMapTransform * vec3( CLEARCOAT_NORMALMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_CLEARCOAT_ROUGHNESSMAP
	vClearcoatRoughnessMapUv = ( clearcoatRoughnessMapTransform * vec3( CLEARCOAT_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCEMAP
	vIridescenceMapUv = ( iridescenceMapTransform * vec3( IRIDESCENCEMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_IRIDESCENCE_THICKNESSMAP
	vIridescenceThicknessMapUv = ( iridescenceThicknessMapTransform * vec3( IRIDESCENCE_THICKNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_COLORMAP
	vSheenColorMapUv = ( sheenColorMapTransform * vec3( SHEEN_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SHEEN_ROUGHNESSMAP
	vSheenRoughnessMapUv = ( sheenRoughnessMapTransform * vec3( SHEEN_ROUGHNESSMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULARMAP
	vSpecularMapUv = ( specularMapTransform * vec3( SPECULARMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_COLORMAP
	vSpecularColorMapUv = ( specularColorMapTransform * vec3( SPECULAR_COLORMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_SPECULAR_INTENSITYMAP
	vSpecularIntensityMapUv = ( specularIntensityMapTransform * vec3( SPECULAR_INTENSITYMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_TRANSMISSIONMAP
	vTransmissionMapUv = ( transmissionMapTransform * vec3( TRANSMISSIONMAP_UV, 1 ) ).xy;
#endif
#ifdef USE_THICKNESSMAP
	vThicknessMapUv = ( thicknessMapTransform * vec3( THICKNESSMAP_UV, 1 ) ).xy;
#endif`,xS=`#if defined( USE_ENVMAP ) || defined( DISTANCE ) || defined ( USE_SHADOWMAP ) || defined ( USE_TRANSMISSION ) || NUM_SPOT_LIGHT_COORDS > 0
	vec4 worldPosition = vec4( transformed, 1.0 );
	#ifdef USE_BATCHING
		worldPosition = batchingMatrix * worldPosition;
	#endif
	#ifdef USE_INSTANCING
		worldPosition = instanceMatrix * worldPosition;
	#endif
	worldPosition = modelMatrix * worldPosition;
#endif`,vS=`varying vec2 vUv;
uniform mat3 uvTransform;
void main() {
	vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	gl_Position = vec4( position.xy, 1.0, 1.0 );
}`,_S=`uniform sampler2D t2D;
uniform float backgroundIntensity;
varying vec2 vUv;
void main() {
	vec4 texColor = texture2D( t2D, vUv );
	#ifdef DECODE_VIDEO_TEXTURE
		texColor = vec4( mix( pow( texColor.rgb * 0.9478672986 + vec3( 0.0521327014 ), vec3( 2.4 ) ), texColor.rgb * 0.0773993808, vec3( lessThanEqual( texColor.rgb, vec3( 0.04045 ) ) ) ), texColor.w );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,yS=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,MS=`#ifdef ENVMAP_TYPE_CUBE
	uniform samplerCube envMap;
#elif defined( ENVMAP_TYPE_CUBE_UV )
	uniform sampler2D envMap;
#endif
uniform float flipEnvMap;
uniform float backgroundBlurriness;
uniform float backgroundIntensity;
uniform mat3 backgroundRotation;
varying vec3 vWorldDirection;
#include <cube_uv_reflection_fragment>
void main() {
	#ifdef ENVMAP_TYPE_CUBE
		vec4 texColor = textureCube( envMap, backgroundRotation * vec3( flipEnvMap * vWorldDirection.x, vWorldDirection.yz ) );
	#elif defined( ENVMAP_TYPE_CUBE_UV )
		vec4 texColor = textureCubeUV( envMap, backgroundRotation * vWorldDirection, backgroundBlurriness );
	#else
		vec4 texColor = vec4( 0.0, 0.0, 0.0, 1.0 );
	#endif
	texColor.rgb *= backgroundIntensity;
	gl_FragColor = texColor;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,SS=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
	gl_Position.z = gl_Position.w;
}`,wS=`uniform samplerCube tCube;
uniform float tFlip;
uniform float opacity;
varying vec3 vWorldDirection;
void main() {
	vec4 texColor = textureCube( tCube, vec3( tFlip * vWorldDirection.x, vWorldDirection.yz ) );
	gl_FragColor = texColor;
	gl_FragColor.a *= opacity;
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,bS=`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
varying vec2 vHighPrecisionZW;
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vHighPrecisionZW = gl_Position.zw;
}`,ES=`#if DEPTH_PACKING == 3200
	uniform float opacity;
#endif
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
varying vec2 vHighPrecisionZW;
void main() {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#if DEPTH_PACKING == 3200
		diffuseColor.a = opacity;
	#endif
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <logdepthbuf_fragment>
	#ifdef USE_REVERSED_DEPTH_BUFFER
		float fragCoordZ = vHighPrecisionZW[ 0 ] / vHighPrecisionZW[ 1 ];
	#else
		float fragCoordZ = 0.5 * vHighPrecisionZW[ 0 ] / vHighPrecisionZW[ 1 ] + 0.5;
	#endif
	#if DEPTH_PACKING == 3200
		gl_FragColor = vec4( vec3( 1.0 - fragCoordZ ), opacity );
	#elif DEPTH_PACKING == 3201
		gl_FragColor = packDepthToRGBA( fragCoordZ );
	#elif DEPTH_PACKING == 3202
		gl_FragColor = vec4( packDepthToRGB( fragCoordZ ), 1.0 );
	#elif DEPTH_PACKING == 3203
		gl_FragColor = vec4( packDepthToRG( fragCoordZ ), 0.0, 1.0 );
	#endif
}`,DS=`#define DISTANCE
varying vec3 vWorldPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <skinbase_vertex>
	#include <morphinstance_vertex>
	#ifdef USE_DISPLACEMENTMAP
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <worldpos_vertex>
	#include <clipping_planes_vertex>
	vWorldPosition = worldPosition.xyz;
}`,AS=`#define DISTANCE
uniform vec3 referencePosition;
uniform float nearDistance;
uniform float farDistance;
varying vec3 vWorldPosition;
#include <common>
#include <packing>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <clipping_planes_pars_fragment>
void main () {
	vec4 diffuseColor = vec4( 1.0 );
	#include <clipping_planes_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	float dist = length( vWorldPosition - referencePosition );
	dist = ( dist - nearDistance ) / ( farDistance - nearDistance );
	dist = saturate( dist );
	gl_FragColor = packDepthToRGBA( dist );
}`,CS=`varying vec3 vWorldDirection;
#include <common>
void main() {
	vWorldDirection = transformDirection( position, modelMatrix );
	#include <begin_vertex>
	#include <project_vertex>
}`,TS=`uniform sampler2D tEquirect;
varying vec3 vWorldDirection;
#include <common>
void main() {
	vec3 direction = normalize( vWorldDirection );
	vec2 sampleUV = equirectUv( direction );
	gl_FragColor = texture2D( tEquirect, sampleUV );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
}`,RS=`uniform float scale;
attribute float lineDistance;
varying float vLineDistance;
#include <common>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	vLineDistance = scale * lineDistance;
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,FS=`uniform vec3 diffuse;
uniform float opacity;
uniform float dashSize;
uniform float totalSize;
varying float vLineDistance;
#include <common>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	if ( mod( vLineDistance, totalSize ) > dashSize ) {
		discard;
	}
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,PS=`#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#if defined ( USE_ENVMAP ) || defined ( USE_SKINNING )
		#include <beginnormal_vertex>
		#include <morphnormal_vertex>
		#include <skinbase_vertex>
		#include <skinnormal_vertex>
		#include <defaultnormal_vertex>
	#endif
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <fog_vertex>
}`,IS=`uniform vec3 diffuse;
uniform float opacity;
#ifndef FLAT_SHADED
	varying vec3 vNormal;
#endif
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	#ifdef USE_LIGHTMAP
		vec4 lightMapTexel = texture2D( lightMap, vLightMapUv );
		reflectedLight.indirectDiffuse += lightMapTexel.rgb * lightMapIntensity * RECIPROCAL_PI;
	#else
		reflectedLight.indirectDiffuse += vec3( 1.0 );
	#endif
	#include <aomap_fragment>
	reflectedLight.indirectDiffuse *= diffuseColor.rgb;
	vec3 outgoingLight = reflectedLight.indirectDiffuse;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,NS=`#define LAMBERT
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,LS=`#define LAMBERT
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_lambert_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_lambert_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,BS=`#define MATCAP
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <color_pars_vertex>
#include <displacementmap_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
	vViewPosition = - mvPosition.xyz;
}`,US=`#define MATCAP
uniform vec3 diffuse;
uniform float opacity;
uniform sampler2D matcap;
varying vec3 vViewPosition;
#include <common>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	vec3 viewDir = normalize( vViewPosition );
	vec3 x = normalize( vec3( viewDir.z, 0.0, - viewDir.x ) );
	vec3 y = cross( viewDir, x );
	vec2 uv = vec2( dot( x, normal ), dot( y, normal ) ) * 0.495 + 0.5;
	#ifdef USE_MATCAP
		vec4 matcapColor = texture2D( matcap, uv );
	#else
		vec4 matcapColor = vec4( vec3( mix( 0.2, 0.8, uv.y ) ), 1.0 );
	#endif
	vec3 outgoingLight = diffuseColor.rgb * matcapColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,OS=`#define NORMAL
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	vViewPosition = - mvPosition.xyz;
#endif
}`,zS=`#define NORMAL
uniform float opacity;
#if defined( FLAT_SHADED ) || defined( USE_BUMPMAP ) || defined( USE_NORMALMAP_TANGENTSPACE )
	varying vec3 vViewPosition;
#endif
#include <packing>
#include <uv_pars_fragment>
#include <normal_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( 0.0, 0.0, 0.0, opacity );
	#include <clipping_planes_fragment>
	#include <logdepthbuf_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	gl_FragColor = vec4( packNormalToRGB( normal ), diffuseColor.a );
	#ifdef OPAQUE
		gl_FragColor.a = 1.0;
	#endif
}`,kS=`#define PHONG
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <envmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <envmap_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,VS=`#define PHONG
uniform vec3 diffuse;
uniform vec3 emissive;
uniform vec3 specular;
uniform float shininess;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_phong_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <specularmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <specularmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_phong_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + reflectedLight.directSpecular + reflectedLight.indirectSpecular + totalEmissiveRadiance;
	#include <envmap_fragment>
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,HS=`#define STANDARD
varying vec3 vViewPosition;
#ifdef USE_TRANSMISSION
	varying vec3 vWorldPosition;
#endif
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
#ifdef USE_TRANSMISSION
	vWorldPosition = worldPosition.xyz;
#endif
}`,GS=`#define STANDARD
#ifdef PHYSICAL
	#define IOR
	#define USE_SPECULAR
#endif
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float roughness;
uniform float metalness;
uniform float opacity;
#ifdef IOR
	uniform float ior;
#endif
#ifdef USE_SPECULAR
	uniform float specularIntensity;
	uniform vec3 specularColor;
	#ifdef USE_SPECULAR_COLORMAP
		uniform sampler2D specularColorMap;
	#endif
	#ifdef USE_SPECULAR_INTENSITYMAP
		uniform sampler2D specularIntensityMap;
	#endif
#endif
#ifdef USE_CLEARCOAT
	uniform float clearcoat;
	uniform float clearcoatRoughness;
#endif
#ifdef USE_DISPERSION
	uniform float dispersion;
#endif
#ifdef USE_IRIDESCENCE
	uniform float iridescence;
	uniform float iridescenceIOR;
	uniform float iridescenceThicknessMinimum;
	uniform float iridescenceThicknessMaximum;
#endif
#ifdef USE_SHEEN
	uniform vec3 sheenColor;
	uniform float sheenRoughness;
	#ifdef USE_SHEEN_COLORMAP
		uniform sampler2D sheenColorMap;
	#endif
	#ifdef USE_SHEEN_ROUGHNESSMAP
		uniform sampler2D sheenRoughnessMap;
	#endif
#endif
#ifdef USE_ANISOTROPY
	uniform vec2 anisotropyVector;
	#ifdef USE_ANISOTROPYMAP
		uniform sampler2D anisotropyMap;
	#endif
#endif
varying vec3 vViewPosition;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <iridescence_fragment>
#include <cube_uv_reflection_fragment>
#include <envmap_common_pars_fragment>
#include <envmap_physical_pars_fragment>
#include <fog_pars_fragment>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_physical_pars_fragment>
#include <transmission_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <clearcoat_pars_fragment>
#include <iridescence_pars_fragment>
#include <roughnessmap_pars_fragment>
#include <metalnessmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <roughnessmap_fragment>
	#include <metalnessmap_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <clearcoat_normal_fragment_begin>
	#include <clearcoat_normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_physical_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 totalDiffuse = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse;
	vec3 totalSpecular = reflectedLight.directSpecular + reflectedLight.indirectSpecular;
	#include <transmission_fragment>
	vec3 outgoingLight = totalDiffuse + totalSpecular + totalEmissiveRadiance;
	#ifdef USE_SHEEN
		float sheenEnergyComp = 1.0 - 0.157 * max3( material.sheenColor );
		outgoingLight = outgoingLight * sheenEnergyComp + sheenSpecularDirect + sheenSpecularIndirect;
	#endif
	#ifdef USE_CLEARCOAT
		float dotNVcc = saturate( dot( geometryClearcoatNormal, geometryViewDir ) );
		vec3 Fcc = F_Schlick( material.clearcoatF0, material.clearcoatF90, dotNVcc );
		outgoingLight = outgoingLight * ( 1.0 - material.clearcoat * Fcc ) + ( clearcoatSpecularDirect + clearcoatSpecularIndirect ) * material.clearcoat;
	#endif
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,WS=`#define TOON
varying vec3 vViewPosition;
#include <common>
#include <batching_pars_vertex>
#include <uv_pars_vertex>
#include <displacementmap_pars_vertex>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <normal_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <shadowmap_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <normal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <displacementmap_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	vViewPosition = - mvPosition.xyz;
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,qS=`#define TOON
uniform vec3 diffuse;
uniform vec3 emissive;
uniform float opacity;
#include <common>
#include <packing>
#include <dithering_pars_fragment>
#include <color_pars_fragment>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <aomap_pars_fragment>
#include <lightmap_pars_fragment>
#include <emissivemap_pars_fragment>
#include <gradientmap_pars_fragment>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <normal_pars_fragment>
#include <lights_toon_pars_fragment>
#include <shadowmap_pars_fragment>
#include <bumpmap_pars_fragment>
#include <normalmap_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	ReflectedLight reflectedLight = ReflectedLight( vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ), vec3( 0.0 ) );
	vec3 totalEmissiveRadiance = emissive;
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <color_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	#include <normal_fragment_begin>
	#include <normal_fragment_maps>
	#include <emissivemap_fragment>
	#include <lights_toon_fragment>
	#include <lights_fragment_begin>
	#include <lights_fragment_maps>
	#include <lights_fragment_end>
	#include <aomap_fragment>
	vec3 outgoingLight = reflectedLight.directDiffuse + reflectedLight.indirectDiffuse + totalEmissiveRadiance;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
	#include <dithering_fragment>
}`,XS=`uniform float size;
uniform float scale;
#include <common>
#include <color_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
#ifdef USE_POINTS_UV
	varying vec2 vUv;
	uniform mat3 uvTransform;
#endif
void main() {
	#ifdef USE_POINTS_UV
		vUv = ( uvTransform * vec3( uv, 1 ) ).xy;
	#endif
	#include <color_vertex>
	#include <morphinstance_vertex>
	#include <morphcolor_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <project_vertex>
	gl_PointSize = size;
	#ifdef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) gl_PointSize *= ( scale / - mvPosition.z );
	#endif
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <worldpos_vertex>
	#include <fog_vertex>
}`,YS=`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <color_pars_fragment>
#include <map_particle_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_particle_fragment>
	#include <color_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
	#include <premultiplied_alpha_fragment>
}`,ZS=`#include <common>
#include <batching_pars_vertex>
#include <fog_pars_vertex>
#include <morphtarget_pars_vertex>
#include <skinning_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <shadowmap_pars_vertex>
void main() {
	#include <batching_vertex>
	#include <beginnormal_vertex>
	#include <morphinstance_vertex>
	#include <morphnormal_vertex>
	#include <skinbase_vertex>
	#include <skinnormal_vertex>
	#include <defaultnormal_vertex>
	#include <begin_vertex>
	#include <morphtarget_vertex>
	#include <skinning_vertex>
	#include <project_vertex>
	#include <logdepthbuf_vertex>
	#include <worldpos_vertex>
	#include <shadowmap_vertex>
	#include <fog_vertex>
}`,$S=`uniform vec3 color;
uniform float opacity;
#include <common>
#include <packing>
#include <fog_pars_fragment>
#include <bsdfs>
#include <lights_pars_begin>
#include <logdepthbuf_pars_fragment>
#include <shadowmap_pars_fragment>
#include <shadowmask_pars_fragment>
void main() {
	#include <logdepthbuf_fragment>
	gl_FragColor = vec4( color, opacity * ( 1.0 - getShadowMask() ) );
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,JS=`uniform float rotation;
uniform vec2 center;
#include <common>
#include <uv_pars_vertex>
#include <fog_pars_vertex>
#include <logdepthbuf_pars_vertex>
#include <clipping_planes_pars_vertex>
void main() {
	#include <uv_vertex>
	vec4 mvPosition = modelViewMatrix[ 3 ];
	vec2 scale = vec2( length( modelMatrix[ 0 ].xyz ), length( modelMatrix[ 1 ].xyz ) );
	#ifndef USE_SIZEATTENUATION
		bool isPerspective = isPerspectiveMatrix( projectionMatrix );
		if ( isPerspective ) scale *= - mvPosition.z;
	#endif
	vec2 alignedPosition = ( position.xy - ( center - vec2( 0.5 ) ) ) * scale;
	vec2 rotatedPosition;
	rotatedPosition.x = cos( rotation ) * alignedPosition.x - sin( rotation ) * alignedPosition.y;
	rotatedPosition.y = sin( rotation ) * alignedPosition.x + cos( rotation ) * alignedPosition.y;
	mvPosition.xy += rotatedPosition;
	gl_Position = projectionMatrix * mvPosition;
	#include <logdepthbuf_vertex>
	#include <clipping_planes_vertex>
	#include <fog_vertex>
}`,KS=`uniform vec3 diffuse;
uniform float opacity;
#include <common>
#include <uv_pars_fragment>
#include <map_pars_fragment>
#include <alphamap_pars_fragment>
#include <alphatest_pars_fragment>
#include <alphahash_pars_fragment>
#include <fog_pars_fragment>
#include <logdepthbuf_pars_fragment>
#include <clipping_planes_pars_fragment>
void main() {
	vec4 diffuseColor = vec4( diffuse, opacity );
	#include <clipping_planes_fragment>
	vec3 outgoingLight = vec3( 0.0 );
	#include <logdepthbuf_fragment>
	#include <map_fragment>
	#include <alphamap_fragment>
	#include <alphatest_fragment>
	#include <alphahash_fragment>
	outgoingLight = diffuseColor.rgb;
	#include <opaque_fragment>
	#include <tonemapping_fragment>
	#include <colorspace_fragment>
	#include <fog_fragment>
}`,je={alphahash_fragment:_1,alphahash_pars_fragment:y1,alphamap_fragment:M1,alphamap_pars_fragment:S1,alphatest_fragment:w1,alphatest_pars_fragment:b1,aomap_fragment:E1,aomap_pars_fragment:D1,batching_pars_vertex:A1,batching_vertex:C1,begin_vertex:T1,beginnormal_vertex:R1,bsdfs:F1,iridescence_fragment:P1,bumpmap_pars_fragment:I1,clipping_planes_fragment:N1,clipping_planes_pars_fragment:L1,clipping_planes_pars_vertex:B1,clipping_planes_vertex:U1,color_fragment:O1,color_pars_fragment:z1,color_pars_vertex:k1,color_vertex:V1,common:H1,cube_uv_reflection_fragment:G1,defaultnormal_vertex:W1,displacementmap_pars_vertex:q1,displacementmap_vertex:X1,emissivemap_fragment:Y1,emissivemap_pars_fragment:Z1,colorspace_fragment:$1,colorspace_pars_fragment:J1,envmap_fragment:K1,envmap_common_pars_fragment:Q1,envmap_pars_fragment:j1,envmap_pars_vertex:eM,envmap_physical_pars_fragment:fM,envmap_vertex:tM,fog_vertex:nM,fog_pars_vertex:rM,fog_fragment:iM,fog_pars_fragment:oM,gradientmap_pars_fragment:sM,lightmap_pars_fragment:aM,lights_lambert_fragment:uM,lights_lambert_pars_fragment:lM,lights_pars_begin:cM,lights_toon_fragment:hM,lights_toon_pars_fragment:dM,lights_phong_fragment:pM,lights_phong_pars_fragment:mM,lights_physical_fragment:gM,lights_physical_pars_fragment:xM,lights_fragment_begin:vM,lights_fragment_maps:_M,lights_fragment_end:yM,logdepthbuf_fragment:MM,logdepthbuf_pars_fragment:SM,logdepthbuf_pars_vertex:wM,logdepthbuf_vertex:bM,map_fragment:EM,map_pars_fragment:DM,map_particle_fragment:AM,map_particle_pars_fragment:CM,metalnessmap_fragment:TM,metalnessmap_pars_fragment:RM,morphinstance_vertex:FM,morphcolor_vertex:PM,morphnormal_vertex:IM,morphtarget_pars_vertex:NM,morphtarget_vertex:LM,normal_fragment_begin:BM,normal_fragment_maps:UM,normal_pars_fragment:OM,normal_pars_vertex:zM,normal_vertex:kM,normalmap_pars_fragment:VM,clearcoat_normal_fragment_begin:HM,clearcoat_normal_fragment_maps:GM,clearcoat_pars_fragment:WM,iridescence_pars_fragment:qM,opaque_fragment:XM,packing:YM,premultiplied_alpha_fragment:ZM,project_vertex:$M,dithering_fragment:JM,dithering_pars_fragment:KM,roughnessmap_fragment:QM,roughnessmap_pars_fragment:jM,shadowmap_pars_fragment:eS,shadowmap_pars_vertex:tS,shadowmap_vertex:nS,shadowmask_pars_fragment:rS,skinbase_vertex:iS,skinning_pars_vertex:oS,skinning_vertex:sS,skinnormal_vertex:aS,specularmap_fragment:uS,specularmap_pars_fragment:lS,tonemapping_fragment:cS,tonemapping_pars_fragment:fS,transmission_fragment:hS,transmission_pars_fragment:dS,uv_pars_fragment:pS,uv_pars_vertex:mS,uv_vertex:gS,worldpos_vertex:xS,background_vert:vS,background_frag:_S,backgroundCube_vert:yS,backgroundCube_frag:MS,cube_vert:SS,cube_frag:wS,depth_vert:bS,depth_frag:ES,distanceRGBA_vert:DS,distanceRGBA_frag:AS,equirect_vert:CS,equirect_frag:TS,linedashed_vert:RS,linedashed_frag:FS,meshbasic_vert:PS,meshbasic_frag:IS,meshlambert_vert:NS,meshlambert_frag:LS,meshmatcap_vert:BS,meshmatcap_frag:US,meshnormal_vert:OS,meshnormal_frag:zS,meshphong_vert:kS,meshphong_frag:VS,meshphysical_vert:HS,meshphysical_frag:GS,meshtoon_vert:WS,meshtoon_frag:qS,points_vert:XS,points_frag:YS,shadow_vert:ZS,shadow_frag:$S,sprite_vert:JS,sprite_frag:KS},we={common:{diffuse:{value:new it(16777215)},opacity:{value:1},map:{value:null},mapTransform:{value:new Ke},alphaMap:{value:null},alphaMapTransform:{value:new Ke},alphaTest:{value:0}},specularmap:{specularMap:{value:null},specularMapTransform:{value:new Ke}},envmap:{envMap:{value:null},envMapRotation:{value:new Ke},flipEnvMap:{value:-1},reflectivity:{value:1},ior:{value:1.5},refractionRatio:{value:.98}},aomap:{aoMap:{value:null},aoMapIntensity:{value:1},aoMapTransform:{value:new Ke}},lightmap:{lightMap:{value:null},lightMapIntensity:{value:1},lightMapTransform:{value:new Ke}},bumpmap:{bumpMap:{value:null},bumpMapTransform:{value:new Ke},bumpScale:{value:1}},normalmap:{normalMap:{value:null},normalMapTransform:{value:new Ke},normalScale:{value:new Ie(1,1)}},displacementmap:{displacementMap:{value:null},displacementMapTransform:{value:new Ke},displacementScale:{value:1},displacementBias:{value:0}},emissivemap:{emissiveMap:{value:null},emissiveMapTransform:{value:new Ke}},metalnessmap:{metalnessMap:{value:null},metalnessMapTransform:{value:new Ke}},roughnessmap:{roughnessMap:{value:null},roughnessMapTransform:{value:new Ke}},gradientmap:{gradientMap:{value:null}},fog:{fogDensity:{value:25e-5},fogNear:{value:1},fogFar:{value:2e3},fogColor:{value:new it(16777215)}},lights:{ambientLightColor:{value:[]},lightProbe:{value:[]},directionalLights:{value:[],properties:{direction:{},color:{}}},directionalLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},directionalShadowMap:{value:[]},directionalShadowMatrix:{value:[]},spotLights:{value:[],properties:{color:{},position:{},direction:{},distance:{},coneCos:{},penumbraCos:{},decay:{}}},spotLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{}}},spotLightMap:{value:[]},spotShadowMap:{value:[]},spotLightMatrix:{value:[]},pointLights:{value:[],properties:{color:{},position:{},decay:{},distance:{}}},pointLightShadows:{value:[],properties:{shadowIntensity:1,shadowBias:{},shadowNormalBias:{},shadowRadius:{},shadowMapSize:{},shadowCameraNear:{},shadowCameraFar:{}}},pointShadowMap:{value:[]},pointShadowMatrix:{value:[]},hemisphereLights:{value:[],properties:{direction:{},skyColor:{},groundColor:{}}},rectAreaLights:{value:[],properties:{color:{},position:{},width:{},height:{}}},ltc_1:{value:null},ltc_2:{value:null}},points:{diffuse:{value:new it(16777215)},opacity:{value:1},size:{value:1},scale:{value:1},map:{value:null},alphaMap:{value:null},alphaMapTransform:{value:new Ke},alphaTest:{value:0},uvTransform:{value:new Ke}},sprite:{diffuse:{value:new it(16777215)},opacity:{value:1},center:{value:new Ie(.5,.5)},rotation:{value:0},map:{value:null},mapTransform:{value:new Ke},alphaMap:{value:null},alphaMapTransform:{value:new Ke},alphaTest:{value:0}}},dr={basic:{uniforms:nn([we.common,we.specularmap,we.envmap,we.aomap,we.lightmap,we.fog]),vertexShader:je.meshbasic_vert,fragmentShader:je.meshbasic_frag},lambert:{uniforms:nn([we.common,we.specularmap,we.envmap,we.aomap,we.lightmap,we.emissivemap,we.bumpmap,we.normalmap,we.displacementmap,we.fog,we.lights,{emissive:{value:new it(0)}}]),vertexShader:je.meshlambert_vert,fragmentShader:je.meshlambert_frag},phong:{uniforms:nn([we.common,we.specularmap,we.envmap,we.aomap,we.lightmap,we.emissivemap,we.bumpmap,we.normalmap,we.displacementmap,we.fog,we.lights,{emissive:{value:new it(0)},specular:{value:new it(1118481)},shininess:{value:30}}]),vertexShader:je.meshphong_vert,fragmentShader:je.meshphong_frag},standard:{uniforms:nn([we.common,we.envmap,we.aomap,we.lightmap,we.emissivemap,we.bumpmap,we.normalmap,we.displacementmap,we.roughnessmap,we.metalnessmap,we.fog,we.lights,{emissive:{value:new it(0)},roughness:{value:1},metalness:{value:0},envMapIntensity:{value:1}}]),vertexShader:je.meshphysical_vert,fragmentShader:je.meshphysical_frag},toon:{uniforms:nn([we.common,we.aomap,we.lightmap,we.emissivemap,we.bumpmap,we.normalmap,we.displacementmap,we.gradientmap,we.fog,we.lights,{emissive:{value:new it(0)}}]),vertexShader:je.meshtoon_vert,fragmentShader:je.meshtoon_frag},matcap:{uniforms:nn([we.common,we.bumpmap,we.normalmap,we.displacementmap,we.fog,{matcap:{value:null}}]),vertexShader:je.meshmatcap_vert,fragmentShader:je.meshmatcap_frag},points:{uniforms:nn([we.points,we.fog]),vertexShader:je.points_vert,fragmentShader:je.points_frag},dashed:{uniforms:nn([we.common,we.fog,{scale:{value:1},dashSize:{value:1},totalSize:{value:2}}]),vertexShader:je.linedashed_vert,fragmentShader:je.linedashed_frag},depth:{uniforms:nn([we.common,we.displacementmap]),vertexShader:je.depth_vert,fragmentShader:je.depth_frag},normal:{uniforms:nn([we.common,we.bumpmap,we.normalmap,we.displacementmap,{opacity:{value:1}}]),vertexShader:je.meshnormal_vert,fragmentShader:je.meshnormal_frag},sprite:{uniforms:nn([we.sprite,we.fog]),vertexShader:je.sprite_vert,fragmentShader:je.sprite_frag},background:{uniforms:{uvTransform:{value:new Ke},t2D:{value:null},backgroundIntensity:{value:1}},vertexShader:je.background_vert,fragmentShader:je.background_frag},backgroundCube:{uniforms:{envMap:{value:null},flipEnvMap:{value:-1},backgroundBlurriness:{value:0},backgroundIntensity:{value:1},backgroundRotation:{value:new Ke}},vertexShader:je.backgroundCube_vert,fragmentShader:je.backgroundCube_frag},cube:{uniforms:{tCube:{value:null},tFlip:{value:-1},opacity:{value:1}},vertexShader:je.cube_vert,fragmentShader:je.cube_frag},equirect:{uniforms:{tEquirect:{value:null}},vertexShader:je.equirect_vert,fragmentShader:je.equirect_frag},distanceRGBA:{uniforms:nn([we.common,we.displacementmap,{referencePosition:{value:new k},nearDistance:{value:1},farDistance:{value:1e3}}]),vertexShader:je.distanceRGBA_vert,fragmentShader:je.distanceRGBA_frag},shadow:{uniforms:nn([we.lights,we.fog,{color:{value:new it(0)},opacity:{value:1}}]),vertexShader:je.shadow_vert,fragmentShader:je.shadow_frag}};dr.physical={uniforms:nn([dr.standard.uniforms,{clearcoat:{value:0},clearcoatMap:{value:null},clearcoatMapTransform:{value:new Ke},clearcoatNormalMap:{value:null},clearcoatNormalMapTransform:{value:new Ke},clearcoatNormalScale:{value:new Ie(1,1)},clearcoatRoughness:{value:0},clearcoatRoughnessMap:{value:null},clearcoatRoughnessMapTransform:{value:new Ke},dispersion:{value:0},iridescence:{value:0},iridescenceMap:{value:null},iridescenceMapTransform:{value:new Ke},iridescenceIOR:{value:1.3},iridescenceThicknessMinimum:{value:100},iridescenceThicknessMaximum:{value:400},iridescenceThicknessMap:{value:null},iridescenceThicknessMapTransform:{value:new Ke},sheen:{value:0},sheenColor:{value:new it(0)},sheenColorMap:{value:null},sheenColorMapTransform:{value:new Ke},sheenRoughness:{value:1},sheenRoughnessMap:{value:null},sheenRoughnessMapTransform:{value:new Ke},transmission:{value:0},transmissionMap:{value:null},transmissionMapTransform:{value:new Ke},transmissionSamplerSize:{value:new Ie},transmissionSamplerMap:{value:null},thickness:{value:0},thicknessMap:{value:null},thicknessMapTransform:{value:new Ke},attenuationDistance:{value:0},attenuationColor:{value:new it(0)},specularColor:{value:new it(1,1,1)},specularColorMap:{value:null},specularColorMapTransform:{value:new Ke},specularIntensity:{value:1},specularIntensityMap:{value:null},specularIntensityMapTransform:{value:new Ke},anisotropyVector:{value:new Ie},anisotropyMap:{value:null},anisotropyMapTransform:{value:new Ke}}]),vertexShader:je.meshphysical_vert,fragmentShader:je.meshphysical_frag};var El={r:0,b:0,g:0},Li=new Kn,QS=new Rt;function jS(t,e,n,r,i,o,s){let a=new it(0),l=o===!0?0:1,u,c,f=null,h=0,d=null;function x(v){let _=v.isScene===!0?v.background:null;return _&&_.isTexture&&(_=(v.backgroundBlurriness>0?n:e).get(_)),_}function p(v){let _=!1,M=x(v);M===null?m(a,l):M&&M.isColor&&(m(M,1),_=!0);let y=t.xr.getEnvironmentBlendMode();y==="additive"?r.buffers.color.setClear(0,0,0,1,s):y==="alpha-blend"&&r.buffers.color.setClear(0,0,0,0,s),(t.autoClear||_)&&(r.buffers.depth.setTest(!0),r.buffers.depth.setMask(!0),r.buffers.color.setMask(!0),t.clear(t.autoClearColor,t.autoClearDepth,t.autoClearStencil))}function g(v,_){let M=x(_);M&&(M.isCubeTexture||M.mapping===qs)?(c===void 0&&(c=new Lt(new Qn(1,1,1),new jn({name:"BackgroundCubeMaterial",uniforms:Ni(dr.backgroundCube.uniforms),vertexShader:dr.backgroundCube.vertexShader,fragmentShader:dr.backgroundCube.fragmentShader,side:fn,depthTest:!1,depthWrite:!1,fog:!1,allowOverride:!1})),c.geometry.deleteAttribute("normal"),c.geometry.deleteAttribute("uv"),c.onBeforeRender=function(y,E,D){this.matrixWorld.copyPosition(D.matrixWorld)},Object.defineProperty(c.material,"envMap",{get:function(){return this.uniforms.envMap.value}}),i.update(c)),Li.copy(_.backgroundRotation),Li.x*=-1,Li.y*=-1,Li.z*=-1,M.isCubeTexture&&M.isRenderTargetTexture===!1&&(Li.y*=-1,Li.z*=-1),c.material.uniforms.envMap.value=M,c.material.uniforms.flipEnvMap.value=M.isCubeTexture&&M.isRenderTargetTexture===!1?-1:1,c.material.uniforms.backgroundBlurriness.value=_.backgroundBlurriness,c.material.uniforms.backgroundIntensity.value=_.backgroundIntensity,c.material.uniforms.backgroundRotation.value.setFromMatrix4(QS.makeRotationFromEuler(Li)),c.material.toneMapped=ct.getTransfer(M.colorSpace)!==gt,(f!==M||h!==M.version||d!==t.toneMapping)&&(c.material.needsUpdate=!0,f=M,h=M.version,d=t.toneMapping),c.layers.enableAll(),v.unshift(c,c.geometry,c.material,0,0,null)):M&&M.isTexture&&(u===void 0&&(u=new Lt(new Ri(2,2),new jn({name:"BackgroundMaterial",uniforms:Ni(dr.background.uniforms),vertexShader:dr.background.vertexShader,fragmentShader:dr.background.fragmentShader,side:Ar,depthTest:!1,depthWrite:!1,fog:!1,allowOverride:!1})),u.geometry.deleteAttribute("normal"),Object.defineProperty(u.material,"map",{get:function(){return this.uniforms.t2D.value}}),i.update(u)),u.material.uniforms.t2D.value=M,u.material.uniforms.backgroundIntensity.value=_.backgroundIntensity,u.material.toneMapped=ct.getTransfer(M.colorSpace)!==gt,M.matrixAutoUpdate===!0&&M.updateMatrix(),u.material.uniforms.uvTransform.value.copy(M.matrix),(f!==M||h!==M.version||d!==t.toneMapping)&&(u.material.needsUpdate=!0,f=M,h=M.version,d=t.toneMapping),u.layers.enableAll(),v.unshift(u,u.geometry,u.material,0,0,null))}function m(v,_){v.getRGB(El,Eh(t)),r.buffers.color.setClear(El.r,El.g,El.b,_,s)}function b(){c!==void 0&&(c.geometry.dispose(),c.material.dispose(),c=void 0),u!==void 0&&(u.geometry.dispose(),u.material.dispose(),u=void 0)}return{getClearColor:function(){return a},setClearColor:function(v,_=1){a.set(v),l=_,m(a,l)},getClearAlpha:function(){return l},setClearAlpha:function(v){l=v,m(a,l)},render:p,addToRenderList:g,dispose:b}}function ew(t,e){let n=t.getParameter(t.MAX_VERTEX_ATTRIBS),r={},i=h(null),o=i,s=!1;function a(w,C,F,O,U){let z=!1,B=f(O,F,C);o!==B&&(o=B,u(o.object)),z=d(w,O,F,U),z&&x(w,O,F,U),U!==null&&e.update(U,t.ELEMENT_ARRAY_BUFFER),(z||s)&&(s=!1,_(w,C,F,O),U!==null&&t.bindBuffer(t.ELEMENT_ARRAY_BUFFER,e.get(U).buffer))}function l(){return t.createVertexArray()}function u(w){return t.bindVertexArray(w)}function c(w){return t.deleteVertexArray(w)}function f(w,C,F){let O=F.wireframe===!0,U=r[w.id];U===void 0&&(U={},r[w.id]=U);let z=U[C.id];z===void 0&&(z={},U[C.id]=z);let B=z[O];return B===void 0&&(B=h(l()),z[O]=B),B}function h(w){let C=[],F=[],O=[];for(let U=0;U<n;U++)C[U]=0,F[U]=0,O[U]=0;return{geometry:null,program:null,wireframe:!1,newAttributes:C,enabledAttributes:F,attributeDivisors:O,object:w,attributes:{},index:null}}function d(w,C,F,O){let U=o.attributes,z=C.attributes,B=0,J=F.getAttributes();for(let H in J)if(J[H].location>=0){let se=U[H],ge=z[H];if(ge===void 0&&(H==="instanceMatrix"&&w.instanceMatrix&&(ge=w.instanceMatrix),H==="instanceColor"&&w.instanceColor&&(ge=w.instanceColor)),se===void 0||se.attribute!==ge||ge&&se.data!==ge.data)return!0;B++}return o.attributesNum!==B||o.index!==O}function x(w,C,F,O){let U={},z=C.attributes,B=0,J=F.getAttributes();for(let H in J)if(J[H].location>=0){let se=z[H];se===void 0&&(H==="instanceMatrix"&&w.instanceMatrix&&(se=w.instanceMatrix),H==="instanceColor"&&w.instanceColor&&(se=w.instanceColor));let ge={};ge.attribute=se,se&&se.data&&(ge.data=se.data),U[H]=ge,B++}o.attributes=U,o.attributesNum=B,o.index=O}function p(){let w=o.newAttributes;for(let C=0,F=w.length;C<F;C++)w[C]=0}function g(w){m(w,0)}function m(w,C){let F=o.newAttributes,O=o.enabledAttributes,U=o.attributeDivisors;F[w]=1,O[w]===0&&(t.enableVertexAttribArray(w),O[w]=1),U[w]!==C&&(t.vertexAttribDivisor(w,C),U[w]=C)}function b(){let w=o.newAttributes,C=o.enabledAttributes;for(let F=0,O=C.length;F<O;F++)C[F]!==w[F]&&(t.disableVertexAttribArray(F),C[F]=0)}function v(w,C,F,O,U,z,B){B===!0?t.vertexAttribIPointer(w,C,F,U,z):t.vertexAttribPointer(w,C,F,O,U,z)}function _(w,C,F,O){p();let U=O.attributes,z=F.getAttributes(),B=C.defaultAttributeValues;for(let J in z){let H=z[J];if(H.location>=0){let ne=U[J];if(ne===void 0&&(J==="instanceMatrix"&&w.instanceMatrix&&(ne=w.instanceMatrix),J==="instanceColor"&&w.instanceColor&&(ne=w.instanceColor)),ne!==void 0){let se=ne.normalized,ge=ne.itemSize,Te=e.get(ne);if(Te===void 0)continue;let ze=Te.buffer,Ze=Te.type,ke=Te.bytesPerElement,re=Ze===t.INT||Ze===t.UNSIGNED_INT||ne.gpuType===qu;if(ne.isInterleavedBufferAttribute){let ae=ne.data,Se=ae.stride,De=ne.offset;if(ae.isInstancedInterleavedBuffer){for(let xe=0;xe<H.locationSize;xe++)m(H.location+xe,ae.meshPerAttribute);w.isInstancedMesh!==!0&&O._maxInstanceCount===void 0&&(O._maxInstanceCount=ae.meshPerAttribute*ae.count)}else for(let xe=0;xe<H.locationSize;xe++)g(H.location+xe);t.bindBuffer(t.ARRAY_BUFFER,ze);for(let xe=0;xe<H.locationSize;xe++)v(H.location+xe,ge/H.locationSize,Ze,se,Se*ke,(De+ge/H.locationSize*xe)*ke,re)}else{if(ne.isInstancedBufferAttribute){for(let ae=0;ae<H.locationSize;ae++)m(H.location+ae,ne.meshPerAttribute);w.isInstancedMesh!==!0&&O._maxInstanceCount===void 0&&(O._maxInstanceCount=ne.meshPerAttribute*ne.count)}else for(let ae=0;ae<H.locationSize;ae++)g(H.location+ae);t.bindBuffer(t.ARRAY_BUFFER,ze);for(let ae=0;ae<H.locationSize;ae++)v(H.location+ae,ge/H.locationSize,Ze,se,ge*ke,ge/H.locationSize*ae*ke,re)}}else if(B!==void 0){let se=B[J];if(se!==void 0)switch(se.length){case 2:t.vertexAttrib2fv(H.location,se);break;case 3:t.vertexAttrib3fv(H.location,se);break;case 4:t.vertexAttrib4fv(H.location,se);break;default:t.vertexAttrib1fv(H.location,se)}}}}b()}function M(){D();for(let w in r){let C=r[w];for(let F in C){let O=C[F];for(let U in O)c(O[U].object),delete O[U];delete C[F]}delete r[w]}}function y(w){if(r[w.id]===void 0)return;let C=r[w.id];for(let F in C){let O=C[F];for(let U in O)c(O[U].object),delete O[U];delete C[F]}delete r[w.id]}function E(w){for(let C in r){let F=r[C];if(F[w.id]===void 0)continue;let O=F[w.id];for(let U in O)c(O[U].object),delete O[U];delete F[w.id]}}function D(){S(),s=!0,o!==i&&(o=i,u(o.object))}function S(){i.geometry=null,i.program=null,i.wireframe=!1}return{setup:a,reset:D,resetDefaultState:S,dispose:M,releaseStatesOfGeometry:y,releaseStatesOfProgram:E,initAttributes:p,enableAttribute:g,disableUnusedAttributes:b}}function tw(t,e,n){let r;function i(u){r=u}function o(u,c){t.drawArrays(r,u,c),n.update(c,r,1)}function s(u,c,f){f!==0&&(t.drawArraysInstanced(r,u,c,f),n.update(c,r,f))}function a(u,c,f){if(f===0)return;e.get("WEBGL_multi_draw").multiDrawArraysWEBGL(r,u,0,c,0,f);let d=0;for(let x=0;x<f;x++)d+=c[x];n.update(d,r,1)}function l(u,c,f,h){if(f===0)return;let d=e.get("WEBGL_multi_draw");if(d===null)for(let x=0;x<u.length;x++)s(u[x],c[x],h[x]);else{d.multiDrawArraysInstancedWEBGL(r,u,0,c,0,h,0,f);let x=0;for(let p=0;p<f;p++)x+=c[p]*h[p];n.update(x,r,1)}}this.setMode=i,this.render=o,this.renderInstances=s,this.renderMultiDraw=a,this.renderMultiDrawInstances=l}function nw(t,e,n,r){let i;function o(){if(i!==void 0)return i;if(e.has("EXT_texture_filter_anisotropic")===!0){let E=e.get("EXT_texture_filter_anisotropic");i=t.getParameter(E.MAX_TEXTURE_MAX_ANISOTROPY_EXT)}else i=0;return i}function s(E){return!(E!==Hn&&r.convert(E)!==t.getParameter(t.IMPLEMENTATION_COLOR_READ_FORMAT))}function a(E){let D=E===Lo&&(e.has("EXT_color_buffer_half_float")||e.has("EXT_color_buffer_float"));return!(E!==er&&r.convert(E)!==t.getParameter(t.IMPLEMENTATION_COLOR_READ_TYPE)&&E!==hr&&!D)}function l(E){if(E==="highp"){if(t.getShaderPrecisionFormat(t.VERTEX_SHADER,t.HIGH_FLOAT).precision>0&&t.getShaderPrecisionFormat(t.FRAGMENT_SHADER,t.HIGH_FLOAT).precision>0)return"highp";E="mediump"}return E==="mediump"&&t.getShaderPrecisionFormat(t.VERTEX_SHADER,t.MEDIUM_FLOAT).precision>0&&t.getShaderPrecisionFormat(t.FRAGMENT_SHADER,t.MEDIUM_FLOAT).precision>0?"mediump":"lowp"}let u=n.precision!==void 0?n.precision:"highp",c=l(u);c!==u&&(console.warn("THREE.WebGLRenderer:",u,"not supported, using",c,"instead."),u=c);let f=n.logarithmicDepthBuffer===!0,h=n.reversedDepthBuffer===!0&&e.has("EXT_clip_control"),d=t.getParameter(t.MAX_TEXTURE_IMAGE_UNITS),x=t.getParameter(t.MAX_VERTEX_TEXTURE_IMAGE_UNITS),p=t.getParameter(t.MAX_TEXTURE_SIZE),g=t.getParameter(t.MAX_CUBE_MAP_TEXTURE_SIZE),m=t.getParameter(t.MAX_VERTEX_ATTRIBS),b=t.getParameter(t.MAX_VERTEX_UNIFORM_VECTORS),v=t.getParameter(t.MAX_VARYING_VECTORS),_=t.getParameter(t.MAX_FRAGMENT_UNIFORM_VECTORS),M=x>0,y=t.getParameter(t.MAX_SAMPLES);return{isWebGL2:!0,getMaxAnisotropy:o,getMaxPrecision:l,textureFormatReadable:s,textureTypeReadable:a,precision:u,logarithmicDepthBuffer:f,reversedDepthBuffer:h,maxTextures:d,maxVertexTextures:x,maxTextureSize:p,maxCubemapSize:g,maxAttributes:m,maxVertexUniforms:b,maxVaryings:v,maxFragmentUniforms:_,vertexTextures:M,maxSamples:y}}function rw(t){let e=this,n=null,r=0,i=!1,o=!1,s=new On,a=new Ke,l={value:null,needsUpdate:!1};this.uniform=l,this.numPlanes=0,this.numIntersection=0,this.init=function(f,h){let d=f.length!==0||h||r!==0||i;return i=h,r=f.length,d},this.beginShadows=function(){o=!0,c(null)},this.endShadows=function(){o=!1},this.setGlobalState=function(f,h){n=c(f,h,0)},this.setState=function(f,h,d){let x=f.clippingPlanes,p=f.clipIntersection,g=f.clipShadows,m=t.get(f);if(!i||x===null||x.length===0||o&&!g)o?c(null):u();else{let b=o?0:r,v=b*4,_=m.clippingState||null;l.value=_,_=c(x,h,v,d);for(let M=0;M!==v;++M)_[M]=n[M];m.clippingState=_,this.numIntersection=p?this.numPlanes:0,this.numPlanes+=b}};function u(){l.value!==n&&(l.value=n,l.needsUpdate=r>0),e.numPlanes=r,e.numIntersection=0}function c(f,h,d,x){let p=f!==null?f.length:0,g=null;if(p!==0){if(g=l.value,x!==!0||g===null){let m=d+p*4,b=h.matrixWorldInverse;a.getNormalMatrix(b),(g===null||g.length<m)&&(g=new Float32Array(m));for(let v=0,_=d;v!==p;++v,_+=4)s.copy(f[v]).applyMatrix4(b,a),s.normal.toArray(g,_),g[_+3]=s.constant}l.value=g,l.needsUpdate=!0}return e.numPlanes=p,e.numIntersection=0,g}}function iw(t){let e=new WeakMap;function n(s,a){return a===Hu?s.mapping=Pi:a===Gu&&(s.mapping=Ii),s}function r(s){if(s&&s.isTexture){let a=s.mapping;if(a===Hu||a===Gu)if(e.has(s)){let l=e.get(s).texture;return n(l,s.mapping)}else{let l=s.image;if(l&&l.height>0){let u=new fu(l.height);return u.fromEquirectangularTexture(t,s),e.set(s,u),s.addEventListener("dispose",i),n(u.texture,s.mapping)}else return null}}return s}function i(s){let a=s.target;a.removeEventListener("dispose",i);let l=e.get(a);l!==void 0&&(e.delete(a),l.dispose())}function o(){e=new WeakMap}return{get:r,dispose:o}}var ko=4,hg=[.125,.215,.35,.446,.526,.582],Oi=20,Rh=new Vs,dg=new it,Fh=null,Ph=0,Ih=0,Nh=!1,Ui=(1+Math.sqrt(5))/2,zo=1/Ui,pg=[new k(-Ui,zo,0),new k(Ui,zo,0),new k(-zo,0,Ui),new k(zo,0,Ui),new k(0,Ui,-zo),new k(0,Ui,zo),new k(-1,1,-1),new k(1,1,-1),new k(-1,1,1),new k(1,1,1)],ow=new k,Cl=class{constructor(e){this._renderer=e,this._pingPongRenderTarget=null,this._lodMax=0,this._cubeSize=0,this._lodPlanes=[],this._sizeLods=[],this._sigmas=[],this._blurMaterial=null,this._cubemapMaterial=null,this._equirectMaterial=null,this._compileMaterial(this._blurMaterial)}fromScene(e,n=0,r=.1,i=100,o={}){let{size:s=256,position:a=ow}=o;Fh=this._renderer.getRenderTarget(),Ph=this._renderer.getActiveCubeFace(),Ih=this._renderer.getActiveMipmapLevel(),Nh=this._renderer.xr.enabled,this._renderer.xr.enabled=!1,this._setSize(s);let l=this._allocateTargets();return l.depthBuffer=!0,this._sceneToCubeUV(e,r,i,l,a),n>0&&this._blur(l,0,0,n),this._applyPMREM(l),this._cleanup(l),l}fromEquirectangular(e,n=null){return this._fromTexture(e,n)}fromCubemap(e,n=null){return this._fromTexture(e,n)}compileCubemapShader(){this._cubemapMaterial===null&&(this._cubemapMaterial=xg(),this._compileMaterial(this._cubemapMaterial))}compileEquirectangularShader(){this._equirectMaterial===null&&(this._equirectMaterial=gg(),this._compileMaterial(this._equirectMaterial))}dispose(){this._dispose(),this._cubemapMaterial!==null&&this._cubemapMaterial.dispose(),this._equirectMaterial!==null&&this._equirectMaterial.dispose()}_setSize(e){this._lodMax=Math.floor(Math.log2(e)),this._cubeSize=Math.pow(2,this._lodMax)}_dispose(){this._blurMaterial!==null&&this._blurMaterial.dispose(),this._pingPongRenderTarget!==null&&this._pingPongRenderTarget.dispose();for(let e=0;e<this._lodPlanes.length;e++)this._lodPlanes[e].dispose()}_cleanup(e){this._renderer.setRenderTarget(Fh,Ph,Ih),this._renderer.xr.enabled=Nh,e.scissorTest=!1,Dl(e,0,0,e.width,e.height)}_fromTexture(e,n){e.mapping===Pi||e.mapping===Ii?this._setSize(e.image.length===0?16:e.image[0].width||e.image[0].image.width):this._setSize(e.image.width/4),Fh=this._renderer.getRenderTarget(),Ph=this._renderer.getActiveCubeFace(),Ih=this._renderer.getActiveMipmapLevel(),Nh=this._renderer.xr.enabled,this._renderer.xr.enabled=!1;let r=n||this._allocateTargets();return this._textureToCubeUV(e,r),this._applyPMREM(r),this._cleanup(r),r}_allocateTargets(){let e=3*Math.max(this._cubeSize,112),n=4*this._cubeSize,r={magFilter:Jn,minFilter:Jn,generateMipmaps:!1,type:Lo,format:Hn,colorSpace:Ai,depthBuffer:!1},i=mg(e,n,r);if(this._pingPongRenderTarget===null||this._pingPongRenderTarget.width!==e||this._pingPongRenderTarget.height!==n){this._pingPongRenderTarget!==null&&this._dispose(),this._pingPongRenderTarget=mg(e,n,r);let{_lodMax:o}=this;({sizeLods:this._sizeLods,lodPlanes:this._lodPlanes,sigmas:this._sigmas}=sw(o)),this._blurMaterial=aw(o,e,n)}return i}_compileMaterial(e){let n=new Lt(this._lodPlanes[0],e);this._renderer.compile(n,Rh)}_sceneToCubeUV(e,n,r,i,o){let l=new tn(90,1,n,r),u=[1,-1,1,1,1,1],c=[1,1,1,-1,-1,-1],f=this._renderer,h=f.autoClear,d=f.toneMapping;f.getClearColor(dg),f.toneMapping=Rr,f.autoClear=!1,f.state.buffers.depth.getReversed()&&(f.setRenderTarget(i),f.clearDepth(),f.setRenderTarget(null));let p=new Ao({name:"PMREM.Background",side:fn,depthWrite:!1,depthTest:!1}),g=new Lt(new Qn,p),m=!1,b=e.background;b?b.isColor&&(p.color.copy(b),e.background=null,m=!0):(p.color.copy(dg),m=!0);for(let v=0;v<6;v++){let _=v%3;_===0?(l.up.set(0,u[v],0),l.position.set(o.x,o.y,o.z),l.lookAt(o.x+c[v],o.y,o.z)):_===1?(l.up.set(0,0,u[v]),l.position.set(o.x,o.y,o.z),l.lookAt(o.x,o.y+c[v],o.z)):(l.up.set(0,u[v],0),l.position.set(o.x,o.y,o.z),l.lookAt(o.x,o.y,o.z+c[v]));let M=this._cubeSize;Dl(i,_*M,v>2?M:0,M,M),f.setRenderTarget(i),m&&f.render(g,l),f.render(e,l)}g.geometry.dispose(),g.material.dispose(),f.toneMapping=d,f.autoClear=h,e.background=b}_textureToCubeUV(e,n){let r=this._renderer,i=e.mapping===Pi||e.mapping===Ii;i?(this._cubemapMaterial===null&&(this._cubemapMaterial=xg()),this._cubemapMaterial.uniforms.flipEnvMap.value=e.isRenderTargetTexture===!1?-1:1):this._equirectMaterial===null&&(this._equirectMaterial=gg());let o=i?this._cubemapMaterial:this._equirectMaterial,s=new Lt(this._lodPlanes[0],o),a=o.uniforms;a.envMap.value=e;let l=this._cubeSize;Dl(n,0,0,3*l,2*l),r.setRenderTarget(n),r.render(s,Rh)}_applyPMREM(e){let n=this._renderer,r=n.autoClear;n.autoClear=!1;let i=this._lodPlanes.length;for(let o=1;o<i;o++){let s=Math.sqrt(this._sigmas[o]*this._sigmas[o]-this._sigmas[o-1]*this._sigmas[o-1]),a=pg[(i-o-1)%pg.length];this._blur(e,o-1,o,s,a)}n.autoClear=r}_blur(e,n,r,i,o){let s=this._pingPongRenderTarget;this._halfBlur(e,s,n,r,i,"latitudinal",o),this._halfBlur(s,e,r,r,i,"longitudinal",o)}_halfBlur(e,n,r,i,o,s,a){let l=this._renderer,u=this._blurMaterial;s!=="latitudinal"&&s!=="longitudinal"&&console.error("blur direction must be either latitudinal or longitudinal!");let c=3,f=new Lt(this._lodPlanes[i],u),h=u.uniforms,d=this._sizeLods[r]-1,x=isFinite(o)?Math.PI/(2*d):2*Math.PI/(2*Oi-1),p=o/x,g=isFinite(o)?1+Math.floor(c*p):Oi;g>Oi&&console.warn(`sigmaRadians, ${o}, is too large and will clip, as it requested ${g} samples when the maximum is set to ${Oi}`);let m=[],b=0;for(let E=0;E<Oi;++E){let D=E/p,S=Math.exp(-D*D/2);m.push(S),E===0?b+=S:E<g&&(b+=2*S)}for(let E=0;E<m.length;E++)m[E]=m[E]/b;h.envMap.value=e.texture,h.samples.value=g,h.weights.value=m,h.latitudinal.value=s==="latitudinal",a&&(h.poleAxis.value=a);let{_lodMax:v}=this;h.dTheta.value=x,h.mipInt.value=v-r;let _=this._sizeLods[i],M=3*_*(i>v-ko?i-v+ko:0),y=4*(this._cubeSize-_);Dl(n,M,y,3*_,2*_),l.setRenderTarget(n),l.render(f,Rh)}};function sw(t){let e=[],n=[],r=[],i=t,o=t-ko+1+hg.length;for(let s=0;s<o;s++){let a=Math.pow(2,i);n.push(a);let l=1/a;s>t-ko?l=hg[s-t+ko-1]:s===0&&(l=0),r.push(l);let u=1/(a-2),c=-u,f=1+u,h=[c,c,f,c,f,f,c,c,f,f,c,f],d=6,x=6,p=3,g=2,m=1,b=new Float32Array(p*x*d),v=new Float32Array(g*x*d),_=new Float32Array(m*x*d);for(let y=0;y<d;y++){let E=y%3*2/3-1,D=y>2?0:-1,S=[E,D,0,E+2/3,D,0,E+2/3,D+1,0,E,D,0,E+2/3,D+1,0,E,D+1,0];b.set(S,p*x*y),v.set(h,g*x*y);let w=[y,y,y,y,y,y];_.set(w,m*x*y)}let M=new cn;M.setAttribute("position",new Cn(b,p)),M.setAttribute("uv",new Cn(v,g)),M.setAttribute("faceIndex",new Cn(_,m)),e.push(M),i>ko&&i--}return{lodPlanes:e,sizeLods:n,sigmas:r}}function mg(t,e,n){let r=new lr(t,e,n);return r.texture.mapping=qs,r.texture.name="PMREM.cubeUv",r.scissorTest=!0,r}function Dl(t,e,n,r,i){t.viewport.set(e,n,r,i),t.scissor.set(e,n,r,i)}function aw(t,e,n){let r=new Float32Array(Oi),i=new k(0,1,0);return new jn({name:"SphericalGaussianBlur",defines:{n:Oi,CUBEUV_TEXEL_WIDTH:1/e,CUBEUV_TEXEL_HEIGHT:1/n,CUBEUV_MAX_MIP:`${t}.0`},uniforms:{envMap:{value:null},samples:{value:1},weights:{value:r},latitudinal:{value:!1},dTheta:{value:0},mipInt:{value:0},poleAxis:{value:i}},vertexShader:Wh(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;
			uniform int samples;
			uniform float weights[ n ];
			uniform bool latitudinal;
			uniform float dTheta;
			uniform float mipInt;
			uniform vec3 poleAxis;

			#define ENVMAP_TYPE_CUBE_UV
			#include <cube_uv_reflection_fragment>

			vec3 getSample( float theta, vec3 axis ) {

				float cosTheta = cos( theta );
				// Rodrigues' axis-angle rotation
				vec3 sampleDirection = vOutputDirection * cosTheta
					+ cross( axis, vOutputDirection ) * sin( theta )
					+ axis * dot( axis, vOutputDirection ) * ( 1.0 - cosTheta );

				return bilinearCubeUV( envMap, sampleDirection, mipInt );

			}

			void main() {

				vec3 axis = latitudinal ? poleAxis : cross( poleAxis, vOutputDirection );

				if ( all( equal( axis, vec3( 0.0 ) ) ) ) {

					axis = vec3( vOutputDirection.z, 0.0, - vOutputDirection.x );

				}

				axis = normalize( axis );

				gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0 );
				gl_FragColor.rgb += weights[ 0 ] * getSample( 0.0, axis );

				for ( int i = 1; i < n; i++ ) {

					if ( i >= samples ) {

						break;

					}

					float theta = dTheta * float( i );
					gl_FragColor.rgb += weights[ i ] * getSample( -1.0 * theta, axis );
					gl_FragColor.rgb += weights[ i ] * getSample( theta, axis );

				}

			}
		`,blending:Tr,depthTest:!1,depthWrite:!1})}function gg(){return new jn({name:"EquirectangularToCubeUV",uniforms:{envMap:{value:null}},vertexShader:Wh(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			varying vec3 vOutputDirection;

			uniform sampler2D envMap;

			#include <common>

			void main() {

				vec3 outputDirection = normalize( vOutputDirection );
				vec2 uv = equirectUv( outputDirection );

				gl_FragColor = vec4( texture2D ( envMap, uv ).rgb, 1.0 );

			}
		`,blending:Tr,depthTest:!1,depthWrite:!1})}function xg(){return new jn({name:"CubemapToCubeUV",uniforms:{envMap:{value:null},flipEnvMap:{value:-1}},vertexShader:Wh(),fragmentShader:`

			precision mediump float;
			precision mediump int;

			uniform float flipEnvMap;

			varying vec3 vOutputDirection;

			uniform samplerCube envMap;

			void main() {

				gl_FragColor = textureCube( envMap, vec3( flipEnvMap * vOutputDirection.x, vOutputDirection.yz ) );

			}
		`,blending:Tr,depthTest:!1,depthWrite:!1})}function Wh(){return`

		precision mediump float;
		precision mediump int;

		attribute float faceIndex;

		varying vec3 vOutputDirection;

		// RH coordinate system; PMREM face-indexing convention
		vec3 getDirection( vec2 uv, float face ) {

			uv = 2.0 * uv - 1.0;

			vec3 direction = vec3( uv, 1.0 );

			if ( face == 0.0 ) {

				direction = direction.zyx; // ( 1, v, u ) pos x

			} else if ( face == 1.0 ) {

				direction = direction.xzy;
				direction.xz *= -1.0; // ( -u, 1, -v ) pos y

			} else if ( face == 2.0 ) {

				direction.x *= -1.0; // ( -u, v, 1 ) pos z

			} else if ( face == 3.0 ) {

				direction = direction.zyx;
				direction.xz *= -1.0; // ( -1, v, -u ) neg x

			} else if ( face == 4.0 ) {

				direction = direction.xzy;
				direction.xy *= -1.0; // ( -u, -1, v ) neg y

			} else if ( face == 5.0 ) {

				direction.z *= -1.0; // ( u, v, -1 ) neg z

			}

			return direction;

		}

		void main() {

			vOutputDirection = getDirection( uv, faceIndex );
			gl_Position = vec4( position, 1.0 );

		}
	`}function uw(t){let e=new WeakMap,n=null;function r(a){if(a&&a.isTexture){let l=a.mapping,u=l===Hu||l===Gu,c=l===Pi||l===Ii;if(u||c){let f=e.get(a),h=f!==void 0?f.texture.pmremVersion:0;if(a.isRenderTargetTexture&&a.pmremVersion!==h)return n===null&&(n=new Cl(t)),f=u?n.fromEquirectangular(a,f):n.fromCubemap(a,f),f.texture.pmremVersion=a.pmremVersion,e.set(a,f),f.texture;if(f!==void 0)return f.texture;{let d=a.image;return u&&d&&d.height>0||c&&d&&i(d)?(n===null&&(n=new Cl(t)),f=u?n.fromEquirectangular(a):n.fromCubemap(a),f.texture.pmremVersion=a.pmremVersion,e.set(a,f),a.addEventListener("dispose",o),f.texture):null}}}return a}function i(a){let l=0,u=6;for(let c=0;c<u;c++)a[c]!==void 0&&l++;return l===u}function o(a){let l=a.target;l.removeEventListener("dispose",o);let u=e.get(l);u!==void 0&&(e.delete(l),u.dispose())}function s(){e=new WeakMap,n!==null&&(n.dispose(),n=null)}return{get:r,dispose:s}}function lw(t){let e={};function n(r){if(e[r]!==void 0)return e[r];let i;switch(r){case"WEBGL_depth_texture":i=t.getExtension("WEBGL_depth_texture")||t.getExtension("MOZ_WEBGL_depth_texture")||t.getExtension("WEBKIT_WEBGL_depth_texture");break;case"EXT_texture_filter_anisotropic":i=t.getExtension("EXT_texture_filter_anisotropic")||t.getExtension("MOZ_EXT_texture_filter_anisotropic")||t.getExtension("WEBKIT_EXT_texture_filter_anisotropic");break;case"WEBGL_compressed_texture_s3tc":i=t.getExtension("WEBGL_compressed_texture_s3tc")||t.getExtension("MOZ_WEBGL_compressed_texture_s3tc")||t.getExtension("WEBKIT_WEBGL_compressed_texture_s3tc");break;case"WEBGL_compressed_texture_pvrtc":i=t.getExtension("WEBGL_compressed_texture_pvrtc")||t.getExtension("WEBKIT_WEBGL_compressed_texture_pvrtc");break;default:i=t.getExtension(r)}return e[r]=i,i}return{has:function(r){return n(r)!==null},init:function(){n("EXT_color_buffer_float"),n("WEBGL_clip_cull_distance"),n("OES_texture_float_linear"),n("EXT_color_buffer_half_float"),n("WEBGL_multisampled_render_to_texture"),n("WEBGL_render_shared_exponent")},get:function(r){let i=n(r);return i===null&&Eo("THREE.WebGLRenderer: "+r+" extension not supported."),i}}}function cw(t,e,n,r){let i={},o=new WeakMap;function s(f){let h=f.target;h.index!==null&&e.remove(h.index);for(let x in h.attributes)e.remove(h.attributes[x]);h.removeEventListener("dispose",s),delete i[h.id];let d=o.get(h);d&&(e.remove(d),o.delete(h)),r.releaseStatesOfGeometry(h),h.isInstancedBufferGeometry===!0&&delete h._maxInstanceCount,n.memory.geometries--}function a(f,h){return i[h.id]===!0||(h.addEventListener("dispose",s),i[h.id]=!0,n.memory.geometries++),h}function l(f){let h=f.attributes;for(let d in h)e.update(h[d],t.ARRAY_BUFFER)}function u(f){let h=[],d=f.index,x=f.attributes.position,p=0;if(d!==null){let b=d.array;p=d.version;for(let v=0,_=b.length;v<_;v+=3){let M=b[v+0],y=b[v+1],E=b[v+2];h.push(M,y,y,E,E,M)}}else if(x!==void 0){let b=x.array;p=x.version;for(let v=0,_=b.length/3-1;v<_;v+=3){let M=v+0,y=v+1,E=v+2;h.push(M,y,y,E,E,M)}}else return;let g=new(bh(h)?As:Ds)(h,1);g.version=p;let m=o.get(f);m&&e.remove(m),o.set(f,g)}function c(f){let h=o.get(f);if(h){let d=f.index;d!==null&&h.version<d.version&&u(f)}else u(f);return o.get(f)}return{get:a,update:l,getWireframeAttribute:c}}function fw(t,e,n){let r;function i(h){r=h}let o,s;function a(h){o=h.type,s=h.bytesPerElement}function l(h,d){t.drawElements(r,d,o,h*s),n.update(d,r,1)}function u(h,d,x){x!==0&&(t.drawElementsInstanced(r,d,o,h*s,x),n.update(d,r,x))}function c(h,d,x){if(x===0)return;e.get("WEBGL_multi_draw").multiDrawElementsWEBGL(r,d,0,o,h,0,x);let g=0;for(let m=0;m<x;m++)g+=d[m];n.update(g,r,1)}function f(h,d,x,p){if(x===0)return;let g=e.get("WEBGL_multi_draw");if(g===null)for(let m=0;m<h.length;m++)u(h[m]/s,d[m],p[m]);else{g.multiDrawElementsInstancedWEBGL(r,d,0,o,h,0,p,0,x);let m=0;for(let b=0;b<x;b++)m+=d[b]*p[b];n.update(m,r,1)}}this.setMode=i,this.setIndex=a,this.render=l,this.renderInstances=u,this.renderMultiDraw=c,this.renderMultiDrawInstances=f}function hw(t){let e={geometries:0,textures:0},n={frame:0,calls:0,triangles:0,points:0,lines:0};function r(o,s,a){switch(n.calls++,s){case t.TRIANGLES:n.triangles+=a*(o/3);break;case t.LINES:n.lines+=a*(o/2);break;case t.LINE_STRIP:n.lines+=a*(o-1);break;case t.LINE_LOOP:n.lines+=a*o;break;case t.POINTS:n.points+=a*o;break;default:console.error("THREE.WebGLInfo: Unknown draw mode:",s);break}}function i(){n.calls=0,n.triangles=0,n.points=0,n.lines=0}return{memory:e,render:n,programs:null,autoReset:!0,reset:i,update:r}}function dw(t,e,n){let r=new WeakMap,i=new Ft;function o(s,a,l){let u=s.morphTargetInfluences,c=a.morphAttributes.position||a.morphAttributes.normal||a.morphAttributes.color,f=c!==void 0?c.length:0,h=r.get(a);if(h===void 0||h.count!==f){let S=function(){E.dispose(),r.delete(a),a.removeEventListener("dispose",S)};h!==void 0&&h.texture.dispose();let d=a.morphAttributes.position!==void 0,x=a.morphAttributes.normal!==void 0,p=a.morphAttributes.color!==void 0,g=a.morphAttributes.position||[],m=a.morphAttributes.normal||[],b=a.morphAttributes.color||[],v=0;d===!0&&(v=1),x===!0&&(v=2),p===!0&&(v=3);let _=a.attributes.position.count*v,M=1;_>e.maxTextureSize&&(M=Math.ceil(_/e.maxTextureSize),_=e.maxTextureSize);let y=new Float32Array(_*M*4*f),E=new bs(y,_,M,f);E.type=hr,E.needsUpdate=!0;let D=v*4;for(let w=0;w<f;w++){let C=g[w],F=m[w],O=b[w],U=_*M*4*w;for(let z=0;z<C.count;z++){let B=z*D;d===!0&&(i.fromBufferAttribute(C,z),y[U+B+0]=i.x,y[U+B+1]=i.y,y[U+B+2]=i.z,y[U+B+3]=0),x===!0&&(i.fromBufferAttribute(F,z),y[U+B+4]=i.x,y[U+B+5]=i.y,y[U+B+6]=i.z,y[U+B+7]=0),p===!0&&(i.fromBufferAttribute(O,z),y[U+B+8]=i.x,y[U+B+9]=i.y,y[U+B+10]=i.z,y[U+B+11]=O.itemSize===4?i.w:1)}}h={count:f,texture:E,size:new Ie(_,M)},r.set(a,h),a.addEventListener("dispose",S)}if(s.isInstancedMesh===!0&&s.morphTexture!==null)l.getUniforms().setValue(t,"morphTexture",s.morphTexture,n);else{let d=0;for(let p=0;p<u.length;p++)d+=u[p];let x=a.morphTargetsRelative?1:1-d;l.getUniforms().setValue(t,"morphTargetBaseInfluence",x),l.getUniforms().setValue(t,"morphTargetInfluences",u)}l.getUniforms().setValue(t,"morphTargetsTexture",h.texture,n),l.getUniforms().setValue(t,"morphTargetsTextureSize",h.size)}return{update:o}}function pw(t,e,n,r){let i=new WeakMap;function o(l){let u=r.render.frame,c=l.geometry,f=e.get(l,c);if(i.get(f)!==u&&(e.update(f),i.set(f,u)),l.isInstancedMesh&&(l.hasEventListener("dispose",a)===!1&&l.addEventListener("dispose",a),i.get(l)!==u&&(n.update(l.instanceMatrix,t.ARRAY_BUFFER),l.instanceColor!==null&&n.update(l.instanceColor,t.ARRAY_BUFFER),i.set(l,u))),l.isSkinnedMesh){let h=l.skeleton;i.get(h)!==u&&(h.update(),i.set(h,u))}return f}function s(){i=new WeakMap}function a(l){let u=l.target;u.removeEventListener("dispose",a),n.remove(u.instanceMatrix),u.instanceColor!==null&&n.remove(u.instanceColor)}return{update:o,dispose:s}}var Bg=new Tn,vg=new Fs(1,1),Ug=new bs,Og=new lu,zg=new Ts,_g=[],yg=[],Mg=new Float32Array(16),Sg=new Float32Array(9),wg=new Float32Array(4);function Ho(t,e,n){let r=t[0];if(r<=0||r>0)return t;let i=e*n,o=_g[i];if(o===void 0&&(o=new Float32Array(i),_g[i]=o),e!==0){r.toArray(o,0);for(let s=1,a=0;s!==e;++s)a+=n,t[s].toArray(o,a)}return o}function Bt(t,e){if(t.length!==e.length)return!1;for(let n=0,r=t.length;n<r;n++)if(t[n]!==e[n])return!1;return!0}function Ut(t,e){for(let n=0,r=e.length;n<r;n++)t[n]=e[n]}function Rl(t,e){let n=yg[e];n===void 0&&(n=new Int32Array(e),yg[e]=n);for(let r=0;r!==e;++r)n[r]=t.allocateTextureUnit();return n}function mw(t,e){let n=this.cache;n[0]!==e&&(t.uniform1f(this.addr,e),n[0]=e)}function gw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y)&&(t.uniform2f(this.addr,e.x,e.y),n[0]=e.x,n[1]=e.y);else{if(Bt(n,e))return;t.uniform2fv(this.addr,e),Ut(n,e)}}function xw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y||n[2]!==e.z)&&(t.uniform3f(this.addr,e.x,e.y,e.z),n[0]=e.x,n[1]=e.y,n[2]=e.z);else if(e.r!==void 0)(n[0]!==e.r||n[1]!==e.g||n[2]!==e.b)&&(t.uniform3f(this.addr,e.r,e.g,e.b),n[0]=e.r,n[1]=e.g,n[2]=e.b);else{if(Bt(n,e))return;t.uniform3fv(this.addr,e),Ut(n,e)}}function vw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y||n[2]!==e.z||n[3]!==e.w)&&(t.uniform4f(this.addr,e.x,e.y,e.z,e.w),n[0]=e.x,n[1]=e.y,n[2]=e.z,n[3]=e.w);else{if(Bt(n,e))return;t.uniform4fv(this.addr,e),Ut(n,e)}}function _w(t,e){let n=this.cache,r=e.elements;if(r===void 0){if(Bt(n,e))return;t.uniformMatrix2fv(this.addr,!1,e),Ut(n,e)}else{if(Bt(n,r))return;wg.set(r),t.uniformMatrix2fv(this.addr,!1,wg),Ut(n,r)}}function yw(t,e){let n=this.cache,r=e.elements;if(r===void 0){if(Bt(n,e))return;t.uniformMatrix3fv(this.addr,!1,e),Ut(n,e)}else{if(Bt(n,r))return;Sg.set(r),t.uniformMatrix3fv(this.addr,!1,Sg),Ut(n,r)}}function Mw(t,e){let n=this.cache,r=e.elements;if(r===void 0){if(Bt(n,e))return;t.uniformMatrix4fv(this.addr,!1,e),Ut(n,e)}else{if(Bt(n,r))return;Mg.set(r),t.uniformMatrix4fv(this.addr,!1,Mg),Ut(n,r)}}function Sw(t,e){let n=this.cache;n[0]!==e&&(t.uniform1i(this.addr,e),n[0]=e)}function ww(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y)&&(t.uniform2i(this.addr,e.x,e.y),n[0]=e.x,n[1]=e.y);else{if(Bt(n,e))return;t.uniform2iv(this.addr,e),Ut(n,e)}}function bw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y||n[2]!==e.z)&&(t.uniform3i(this.addr,e.x,e.y,e.z),n[0]=e.x,n[1]=e.y,n[2]=e.z);else{if(Bt(n,e))return;t.uniform3iv(this.addr,e),Ut(n,e)}}function Ew(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y||n[2]!==e.z||n[3]!==e.w)&&(t.uniform4i(this.addr,e.x,e.y,e.z,e.w),n[0]=e.x,n[1]=e.y,n[2]=e.z,n[3]=e.w);else{if(Bt(n,e))return;t.uniform4iv(this.addr,e),Ut(n,e)}}function Dw(t,e){let n=this.cache;n[0]!==e&&(t.uniform1ui(this.addr,e),n[0]=e)}function Aw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y)&&(t.uniform2ui(this.addr,e.x,e.y),n[0]=e.x,n[1]=e.y);else{if(Bt(n,e))return;t.uniform2uiv(this.addr,e),Ut(n,e)}}function Cw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y||n[2]!==e.z)&&(t.uniform3ui(this.addr,e.x,e.y,e.z),n[0]=e.x,n[1]=e.y,n[2]=e.z);else{if(Bt(n,e))return;t.uniform3uiv(this.addr,e),Ut(n,e)}}function Tw(t,e){let n=this.cache;if(e.x!==void 0)(n[0]!==e.x||n[1]!==e.y||n[2]!==e.z||n[3]!==e.w)&&(t.uniform4ui(this.addr,e.x,e.y,e.z,e.w),n[0]=e.x,n[1]=e.y,n[2]=e.z,n[3]=e.w);else{if(Bt(n,e))return;t.uniform4uiv(this.addr,e),Ut(n,e)}}function Rw(t,e,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(t.uniform1i(this.addr,i),r[0]=i);let o;this.type===t.SAMPLER_2D_SHADOW?(vg.compareFunction=yh,o=vg):o=Bg,n.setTexture2D(e||o,i)}function Fw(t,e,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(t.uniform1i(this.addr,i),r[0]=i),n.setTexture3D(e||Og,i)}function Pw(t,e,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(t.uniform1i(this.addr,i),r[0]=i),n.setTextureCube(e||zg,i)}function Iw(t,e,n){let r=this.cache,i=n.allocateTextureUnit();r[0]!==i&&(t.uniform1i(this.addr,i),r[0]=i),n.setTexture2DArray(e||Ug,i)}function Nw(t){switch(t){case 5126:return mw;case 35664:return gw;case 35665:return xw;case 35666:return vw;case 35674:return _w;case 35675:return yw;case 35676:return Mw;case 5124:case 35670:return Sw;case 35667:case 35671:return ww;case 35668:case 35672:return bw;case 35669:case 35673:return Ew;case 5125:return Dw;case 36294:return Aw;case 36295:return Cw;case 36296:return Tw;case 35678:case 36198:case 36298:case 36306:case 35682:return Rw;case 35679:case 36299:case 36307:return Fw;case 35680:case 36300:case 36308:case 36293:return Pw;case 36289:case 36303:case 36311:case 36292:return Iw}}function Lw(t,e){t.uniform1fv(this.addr,e)}function Bw(t,e){let n=Ho(e,this.size,2);t.uniform2fv(this.addr,n)}function Uw(t,e){let n=Ho(e,this.size,3);t.uniform3fv(this.addr,n)}function Ow(t,e){let n=Ho(e,this.size,4);t.uniform4fv(this.addr,n)}function zw(t,e){let n=Ho(e,this.size,4);t.uniformMatrix2fv(this.addr,!1,n)}function kw(t,e){let n=Ho(e,this.size,9);t.uniformMatrix3fv(this.addr,!1,n)}function Vw(t,e){let n=Ho(e,this.size,16);t.uniformMatrix4fv(this.addr,!1,n)}function Hw(t,e){t.uniform1iv(this.addr,e)}function Gw(t,e){t.uniform2iv(this.addr,e)}function Ww(t,e){t.uniform3iv(this.addr,e)}function qw(t,e){t.uniform4iv(this.addr,e)}function Xw(t,e){t.uniform1uiv(this.addr,e)}function Yw(t,e){t.uniform2uiv(this.addr,e)}function Zw(t,e){t.uniform3uiv(this.addr,e)}function $w(t,e){t.uniform4uiv(this.addr,e)}function Jw(t,e,n){let r=this.cache,i=e.length,o=Rl(n,i);Bt(r,o)||(t.uniform1iv(this.addr,o),Ut(r,o));for(let s=0;s!==i;++s)n.setTexture2D(e[s]||Bg,o[s])}function Kw(t,e,n){let r=this.cache,i=e.length,o=Rl(n,i);Bt(r,o)||(t.uniform1iv(this.addr,o),Ut(r,o));for(let s=0;s!==i;++s)n.setTexture3D(e[s]||Og,o[s])}function Qw(t,e,n){let r=this.cache,i=e.length,o=Rl(n,i);Bt(r,o)||(t.uniform1iv(this.addr,o),Ut(r,o));for(let s=0;s!==i;++s)n.setTextureCube(e[s]||zg,o[s])}function jw(t,e,n){let r=this.cache,i=e.length,o=Rl(n,i);Bt(r,o)||(t.uniform1iv(this.addr,o),Ut(r,o));for(let s=0;s!==i;++s)n.setTexture2DArray(e[s]||Ug,o[s])}function eb(t){switch(t){case 5126:return Lw;case 35664:return Bw;case 35665:return Uw;case 35666:return Ow;case 35674:return zw;case 35675:return kw;case 35676:return Vw;case 5124:case 35670:return Hw;case 35667:case 35671:return Gw;case 35668:case 35672:return Ww;case 35669:case 35673:return qw;case 5125:return Xw;case 36294:return Yw;case 36295:return Zw;case 36296:return $w;case 35678:case 36198:case 36298:case 36306:case 35682:return Jw;case 35679:case 36299:case 36307:return Kw;case 35680:case 36300:case 36308:case 36293:return Qw;case 36289:case 36303:case 36311:case 36292:return jw}}var Bh=class{constructor(e,n,r){this.id=e,this.addr=r,this.cache=[],this.type=n.type,this.setValue=Nw(n.type)}},Uh=class{constructor(e,n,r){this.id=e,this.addr=r,this.cache=[],this.type=n.type,this.size=n.size,this.setValue=eb(n.type)}},Oh=class{constructor(e){this.id=e,this.seq=[],this.map={}}setValue(e,n,r){let i=this.seq;for(let o=0,s=i.length;o!==s;++o){let a=i[o];a.setValue(e,n[a.id],r)}}},Lh=/(\w+)(\])?(\[|\.)?/g;function bg(t,e){t.seq.push(e),t.map[e.id]=e}function tb(t,e,n){let r=t.name,i=r.length;for(Lh.lastIndex=0;;){let o=Lh.exec(r),s=Lh.lastIndex,a=o[1],l=o[2]==="]",u=o[3];if(l&&(a=a|0),u===void 0||u==="["&&s+2===i){bg(n,u===void 0?new Bh(a,t,e):new Uh(a,t,e));break}else{let f=n.map[a];f===void 0&&(f=new Oh(a),bg(n,f)),n=f}}}var Vo=class{constructor(e,n){this.seq=[],this.map={};let r=e.getProgramParameter(n,e.ACTIVE_UNIFORMS);for(let i=0;i<r;++i){let o=e.getActiveUniform(n,i),s=e.getUniformLocation(n,o.name);tb(o,s,this)}}setValue(e,n,r,i){let o=this.map[n];o!==void 0&&o.setValue(e,r,i)}setOptional(e,n,r){let i=n[r];i!==void 0&&this.setValue(e,r,i)}static upload(e,n,r,i){for(let o=0,s=n.length;o!==s;++o){let a=n[o],l=r[a.id];l.needsUpdate!==!1&&a.setValue(e,l.value,i)}}static seqWithValue(e,n){let r=[];for(let i=0,o=e.length;i!==o;++i){let s=e[i];s.id in n&&r.push(s)}return r}};function Eg(t,e,n){let r=t.createShader(e);return t.shaderSource(r,n),t.compileShader(r),r}var nb=37297,rb=0;function ib(t,e){let n=t.split(`
`),r=[],i=Math.max(e-6,0),o=Math.min(e+6,n.length);for(let s=i;s<o;s++){let a=s+1;r.push(`${a===e?">":" "} ${a}: ${n[s]}`)}return r.join(`
`)}var Dg=new Ke;function ob(t){ct._getMatrix(Dg,ct.workingColorSpace,t);let e=`mat3( ${Dg.elements.map(n=>n.toFixed(4))} )`;switch(ct.getTransfer(t)){case Ms:return[e,"LinearTransferOETF"];case gt:return[e,"sRGBTransferOETF"];default:return console.warn("THREE.WebGLProgram: Unsupported color space: ",t),[e,"LinearTransferOETF"]}}function Ag(t,e,n){let r=t.getShaderParameter(e,t.COMPILE_STATUS),o=(t.getShaderInfoLog(e)||"").trim();if(r&&o==="")return"";let s=/ERROR: 0:(\d+)/.exec(o);if(s){let a=parseInt(s[1]);return n.toUpperCase()+`

`+o+`

`+ib(t.getShaderSource(e),a)}else return o}function sb(t,e){let n=ob(e);return[`vec4 ${t}( vec4 value ) {`,`	return ${n[1]}( vec4( value.rgb * ${n[0]}, value.a ) );`,"}"].join(`
`)}function ab(t,e){let n;switch(e){case Gm:n="Linear";break;case Wm:n="Reinhard";break;case qm:n="Cineon";break;case Xm:n="ACESFilmic";break;case Zm:n="AgX";break;case $m:n="Neutral";break;case Ym:n="Custom";break;default:console.warn("THREE.WebGLProgram: Unsupported toneMapping:",e),n="Linear"}return"vec3 "+t+"( vec3 color ) { return "+n+"ToneMapping( color ); }"}var Al=new k;function ub(){ct.getLuminanceCoefficients(Al);let t=Al.x.toFixed(4),e=Al.y.toFixed(4),n=Al.z.toFixed(4);return["float luminance( const in vec3 rgb ) {",`	const vec3 weights = vec3( ${t}, ${e}, ${n} );`,"	return dot( weights, rgb );","}"].join(`
`)}function lb(t){return[t.extensionClipCullDistance?"#extension GL_ANGLE_clip_cull_distance : require":"",t.extensionMultiDraw?"#extension GL_ANGLE_multi_draw : require":""].filter(Ks).join(`
`)}function cb(t){let e=[];for(let n in t){let r=t[n];r!==!1&&e.push("#define "+n+" "+r)}return e.join(`
`)}function fb(t,e){let n={},r=t.getProgramParameter(e,t.ACTIVE_ATTRIBUTES);for(let i=0;i<r;i++){let o=t.getActiveAttrib(e,i),s=o.name,a=1;o.type===t.FLOAT_MAT2&&(a=2),o.type===t.FLOAT_MAT3&&(a=3),o.type===t.FLOAT_MAT4&&(a=4),n[s]={type:o.type,location:t.getAttribLocation(e,s),locationSize:a}}return n}function Ks(t){return t!==""}function Cg(t,e){let n=e.numSpotLightShadows+e.numSpotLightMaps-e.numSpotLightShadowsWithMaps;return t.replace(/NUM_DIR_LIGHTS/g,e.numDirLights).replace(/NUM_SPOT_LIGHTS/g,e.numSpotLights).replace(/NUM_SPOT_LIGHT_MAPS/g,e.numSpotLightMaps).replace(/NUM_SPOT_LIGHT_COORDS/g,n).replace(/NUM_RECT_AREA_LIGHTS/g,e.numRectAreaLights).replace(/NUM_POINT_LIGHTS/g,e.numPointLights).replace(/NUM_HEMI_LIGHTS/g,e.numHemiLights).replace(/NUM_DIR_LIGHT_SHADOWS/g,e.numDirLightShadows).replace(/NUM_SPOT_LIGHT_SHADOWS_WITH_MAPS/g,e.numSpotLightShadowsWithMaps).replace(/NUM_SPOT_LIGHT_SHADOWS/g,e.numSpotLightShadows).replace(/NUM_POINT_LIGHT_SHADOWS/g,e.numPointLightShadows)}function Tg(t,e){return t.replace(/NUM_CLIPPING_PLANES/g,e.numClippingPlanes).replace(/UNION_CLIPPING_PLANES/g,e.numClippingPlanes-e.numClipIntersection)}var hb=/^[ \t]*#include +<([\w\d./]+)>/gm;function zh(t){return t.replace(hb,pb)}var db=new Map;function pb(t,e){let n=je[e];if(n===void 0){let r=db.get(e);if(r!==void 0)n=je[r],console.warn('THREE.WebGLRenderer: Shader chunk "%s" has been deprecated. Use "%s" instead.',e,r);else throw new Error("Can not resolve #include <"+e+">")}return zh(n)}var mb=/#pragma unroll_loop_start\s+for\s*\(\s*int\s+i\s*=\s*(\d+)\s*;\s*i\s*<\s*(\d+)\s*;\s*i\s*\+\+\s*\)\s*{([\s\S]+?)}\s+#pragma unroll_loop_end/g;function Rg(t){return t.replace(mb,gb)}function gb(t,e,n,r){let i="";for(let o=parseInt(e);o<parseInt(n);o++)i+=r.replace(/\[\s*i\s*\]/g,"[ "+o+" ]").replace(/UNROLLED_LOOP_INDEX/g,o);return i}function Fg(t){let e=`precision ${t.precision} float;
	precision ${t.precision} int;
	precision ${t.precision} sampler2D;
	precision ${t.precision} samplerCube;
	precision ${t.precision} sampler3D;
	precision ${t.precision} sampler2DArray;
	precision ${t.precision} sampler2DShadow;
	precision ${t.precision} samplerCubeShadow;
	precision ${t.precision} sampler2DArrayShadow;
	precision ${t.precision} isampler2D;
	precision ${t.precision} isampler3D;
	precision ${t.precision} isamplerCube;
	precision ${t.precision} isampler2DArray;
	precision ${t.precision} usampler2D;
	precision ${t.precision} usampler3D;
	precision ${t.precision} usamplerCube;
	precision ${t.precision} usampler2DArray;
	`;return t.precision==="highp"?e+=`
#define HIGH_PRECISION`:t.precision==="mediump"?e+=`
#define MEDIUM_PRECISION`:t.precision==="lowp"&&(e+=`
#define LOW_PRECISION`),e}function xb(t){let e="SHADOWMAP_TYPE_BASIC";return t.shadowMapType===oh?e="SHADOWMAP_TYPE_PCF":t.shadowMapType===Sm?e="SHADOWMAP_TYPE_PCF_SOFT":t.shadowMapType===cr&&(e="SHADOWMAP_TYPE_VSM"),e}function vb(t){let e="ENVMAP_TYPE_CUBE";if(t.envMap)switch(t.envMapMode){case Pi:case Ii:e="ENVMAP_TYPE_CUBE";break;case qs:e="ENVMAP_TYPE_CUBE_UV";break}return e}function _b(t){let e="ENVMAP_MODE_REFLECTION";if(t.envMap)switch(t.envMapMode){case Ii:e="ENVMAP_MODE_REFRACTION";break}return e}function yb(t){let e="ENVMAP_BLENDING_NONE";if(t.envMap)switch(t.combine){case lh:e="ENVMAP_BLENDING_MULTIPLY";break;case Vm:e="ENVMAP_BLENDING_MIX";break;case Hm:e="ENVMAP_BLENDING_ADD";break}return e}function Mb(t){let e=t.envMapCubeUVHeight;if(e===null)return null;let n=Math.log2(e)-2,r=1/e;return{texelWidth:1/(3*Math.max(Math.pow(2,n),112)),texelHeight:r,maxMip:n}}function Sb(t,e,n,r){let i=t.getContext(),o=n.defines,s=n.vertexShader,a=n.fragmentShader,l=xb(n),u=vb(n),c=_b(n),f=yb(n),h=Mb(n),d=lb(n),x=cb(o),p=i.createProgram(),g,m,b=n.glslVersion?"#version "+n.glslVersion+`
`:"";n.isRawShaderMaterial?(g=["#define SHADER_TYPE "+n.shaderType,"#define SHADER_NAME "+n.shaderName,x].filter(Ks).join(`
`),g.length>0&&(g+=`
`),m=["#define SHADER_TYPE "+n.shaderType,"#define SHADER_NAME "+n.shaderName,x].filter(Ks).join(`
`),m.length>0&&(m+=`
`)):(g=[Fg(n),"#define SHADER_TYPE "+n.shaderType,"#define SHADER_NAME "+n.shaderName,x,n.extensionClipCullDistance?"#define USE_CLIP_DISTANCE":"",n.batching?"#define USE_BATCHING":"",n.batchingColor?"#define USE_BATCHING_COLOR":"",n.instancing?"#define USE_INSTANCING":"",n.instancingColor?"#define USE_INSTANCING_COLOR":"",n.instancingMorph?"#define USE_INSTANCING_MORPH":"",n.useFog&&n.fog?"#define USE_FOG":"",n.useFog&&n.fogExp2?"#define FOG_EXP2":"",n.map?"#define USE_MAP":"",n.envMap?"#define USE_ENVMAP":"",n.envMap?"#define "+c:"",n.lightMap?"#define USE_LIGHTMAP":"",n.aoMap?"#define USE_AOMAP":"",n.bumpMap?"#define USE_BUMPMAP":"",n.normalMap?"#define USE_NORMALMAP":"",n.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",n.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",n.displacementMap?"#define USE_DISPLACEMENTMAP":"",n.emissiveMap?"#define USE_EMISSIVEMAP":"",n.anisotropy?"#define USE_ANISOTROPY":"",n.anisotropyMap?"#define USE_ANISOTROPYMAP":"",n.clearcoatMap?"#define USE_CLEARCOATMAP":"",n.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",n.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",n.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",n.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",n.specularMap?"#define USE_SPECULARMAP":"",n.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",n.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",n.roughnessMap?"#define USE_ROUGHNESSMAP":"",n.metalnessMap?"#define USE_METALNESSMAP":"",n.alphaMap?"#define USE_ALPHAMAP":"",n.alphaHash?"#define USE_ALPHAHASH":"",n.transmission?"#define USE_TRANSMISSION":"",n.transmissionMap?"#define USE_TRANSMISSIONMAP":"",n.thicknessMap?"#define USE_THICKNESSMAP":"",n.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",n.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",n.mapUv?"#define MAP_UV "+n.mapUv:"",n.alphaMapUv?"#define ALPHAMAP_UV "+n.alphaMapUv:"",n.lightMapUv?"#define LIGHTMAP_UV "+n.lightMapUv:"",n.aoMapUv?"#define AOMAP_UV "+n.aoMapUv:"",n.emissiveMapUv?"#define EMISSIVEMAP_UV "+n.emissiveMapUv:"",n.bumpMapUv?"#define BUMPMAP_UV "+n.bumpMapUv:"",n.normalMapUv?"#define NORMALMAP_UV "+n.normalMapUv:"",n.displacementMapUv?"#define DISPLACEMENTMAP_UV "+n.displacementMapUv:"",n.metalnessMapUv?"#define METALNESSMAP_UV "+n.metalnessMapUv:"",n.roughnessMapUv?"#define ROUGHNESSMAP_UV "+n.roughnessMapUv:"",n.anisotropyMapUv?"#define ANISOTROPYMAP_UV "+n.anisotropyMapUv:"",n.clearcoatMapUv?"#define CLEARCOATMAP_UV "+n.clearcoatMapUv:"",n.clearcoatNormalMapUv?"#define CLEARCOAT_NORMALMAP_UV "+n.clearcoatNormalMapUv:"",n.clearcoatRoughnessMapUv?"#define CLEARCOAT_ROUGHNESSMAP_UV "+n.clearcoatRoughnessMapUv:"",n.iridescenceMapUv?"#define IRIDESCENCEMAP_UV "+n.iridescenceMapUv:"",n.iridescenceThicknessMapUv?"#define IRIDESCENCE_THICKNESSMAP_UV "+n.iridescenceThicknessMapUv:"",n.sheenColorMapUv?"#define SHEEN_COLORMAP_UV "+n.sheenColorMapUv:"",n.sheenRoughnessMapUv?"#define SHEEN_ROUGHNESSMAP_UV "+n.sheenRoughnessMapUv:"",n.specularMapUv?"#define SPECULARMAP_UV "+n.specularMapUv:"",n.specularColorMapUv?"#define SPECULAR_COLORMAP_UV "+n.specularColorMapUv:"",n.specularIntensityMapUv?"#define SPECULAR_INTENSITYMAP_UV "+n.specularIntensityMapUv:"",n.transmissionMapUv?"#define TRANSMISSIONMAP_UV "+n.transmissionMapUv:"",n.thicknessMapUv?"#define THICKNESSMAP_UV "+n.thicknessMapUv:"",n.vertexTangents&&n.flatShading===!1?"#define USE_TANGENT":"",n.vertexColors?"#define USE_COLOR":"",n.vertexAlphas?"#define USE_COLOR_ALPHA":"",n.vertexUv1s?"#define USE_UV1":"",n.vertexUv2s?"#define USE_UV2":"",n.vertexUv3s?"#define USE_UV3":"",n.pointsUvs?"#define USE_POINTS_UV":"",n.flatShading?"#define FLAT_SHADED":"",n.skinning?"#define USE_SKINNING":"",n.morphTargets?"#define USE_MORPHTARGETS":"",n.morphNormals&&n.flatShading===!1?"#define USE_MORPHNORMALS":"",n.morphColors?"#define USE_MORPHCOLORS":"",n.morphTargetsCount>0?"#define MORPHTARGETS_TEXTURE_STRIDE "+n.morphTextureStride:"",n.morphTargetsCount>0?"#define MORPHTARGETS_COUNT "+n.morphTargetsCount:"",n.doubleSided?"#define DOUBLE_SIDED":"",n.flipSided?"#define FLIP_SIDED":"",n.shadowMapEnabled?"#define USE_SHADOWMAP":"",n.shadowMapEnabled?"#define "+l:"",n.sizeAttenuation?"#define USE_SIZEATTENUATION":"",n.numLightProbes>0?"#define USE_LIGHT_PROBES":"",n.logarithmicDepthBuffer?"#define USE_LOGARITHMIC_DEPTH_BUFFER":"",n.reversedDepthBuffer?"#define USE_REVERSED_DEPTH_BUFFER":"","uniform mat4 modelMatrix;","uniform mat4 modelViewMatrix;","uniform mat4 projectionMatrix;","uniform mat4 viewMatrix;","uniform mat3 normalMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;","#ifdef USE_INSTANCING","	attribute mat4 instanceMatrix;","#endif","#ifdef USE_INSTANCING_COLOR","	attribute vec3 instanceColor;","#endif","#ifdef USE_INSTANCING_MORPH","	uniform sampler2D morphTexture;","#endif","attribute vec3 position;","attribute vec3 normal;","attribute vec2 uv;","#ifdef USE_UV1","	attribute vec2 uv1;","#endif","#ifdef USE_UV2","	attribute vec2 uv2;","#endif","#ifdef USE_UV3","	attribute vec2 uv3;","#endif","#ifdef USE_TANGENT","	attribute vec4 tangent;","#endif","#if defined( USE_COLOR_ALPHA )","	attribute vec4 color;","#elif defined( USE_COLOR )","	attribute vec3 color;","#endif","#ifdef USE_SKINNING","	attribute vec4 skinIndex;","	attribute vec4 skinWeight;","#endif",`
`].filter(Ks).join(`
`),m=[Fg(n),"#define SHADER_TYPE "+n.shaderType,"#define SHADER_NAME "+n.shaderName,x,n.useFog&&n.fog?"#define USE_FOG":"",n.useFog&&n.fogExp2?"#define FOG_EXP2":"",n.alphaToCoverage?"#define ALPHA_TO_COVERAGE":"",n.map?"#define USE_MAP":"",n.matcap?"#define USE_MATCAP":"",n.envMap?"#define USE_ENVMAP":"",n.envMap?"#define "+u:"",n.envMap?"#define "+c:"",n.envMap?"#define "+f:"",h?"#define CUBEUV_TEXEL_WIDTH "+h.texelWidth:"",h?"#define CUBEUV_TEXEL_HEIGHT "+h.texelHeight:"",h?"#define CUBEUV_MAX_MIP "+h.maxMip+".0":"",n.lightMap?"#define USE_LIGHTMAP":"",n.aoMap?"#define USE_AOMAP":"",n.bumpMap?"#define USE_BUMPMAP":"",n.normalMap?"#define USE_NORMALMAP":"",n.normalMapObjectSpace?"#define USE_NORMALMAP_OBJECTSPACE":"",n.normalMapTangentSpace?"#define USE_NORMALMAP_TANGENTSPACE":"",n.emissiveMap?"#define USE_EMISSIVEMAP":"",n.anisotropy?"#define USE_ANISOTROPY":"",n.anisotropyMap?"#define USE_ANISOTROPYMAP":"",n.clearcoat?"#define USE_CLEARCOAT":"",n.clearcoatMap?"#define USE_CLEARCOATMAP":"",n.clearcoatRoughnessMap?"#define USE_CLEARCOAT_ROUGHNESSMAP":"",n.clearcoatNormalMap?"#define USE_CLEARCOAT_NORMALMAP":"",n.dispersion?"#define USE_DISPERSION":"",n.iridescence?"#define USE_IRIDESCENCE":"",n.iridescenceMap?"#define USE_IRIDESCENCEMAP":"",n.iridescenceThicknessMap?"#define USE_IRIDESCENCE_THICKNESSMAP":"",n.specularMap?"#define USE_SPECULARMAP":"",n.specularColorMap?"#define USE_SPECULAR_COLORMAP":"",n.specularIntensityMap?"#define USE_SPECULAR_INTENSITYMAP":"",n.roughnessMap?"#define USE_ROUGHNESSMAP":"",n.metalnessMap?"#define USE_METALNESSMAP":"",n.alphaMap?"#define USE_ALPHAMAP":"",n.alphaTest?"#define USE_ALPHATEST":"",n.alphaHash?"#define USE_ALPHAHASH":"",n.sheen?"#define USE_SHEEN":"",n.sheenColorMap?"#define USE_SHEEN_COLORMAP":"",n.sheenRoughnessMap?"#define USE_SHEEN_ROUGHNESSMAP":"",n.transmission?"#define USE_TRANSMISSION":"",n.transmissionMap?"#define USE_TRANSMISSIONMAP":"",n.thicknessMap?"#define USE_THICKNESSMAP":"",n.vertexTangents&&n.flatShading===!1?"#define USE_TANGENT":"",n.vertexColors||n.instancingColor||n.batchingColor?"#define USE_COLOR":"",n.vertexAlphas?"#define USE_COLOR_ALPHA":"",n.vertexUv1s?"#define USE_UV1":"",n.vertexUv2s?"#define USE_UV2":"",n.vertexUv3s?"#define USE_UV3":"",n.pointsUvs?"#define USE_POINTS_UV":"",n.gradientMap?"#define USE_GRADIENTMAP":"",n.flatShading?"#define FLAT_SHADED":"",n.doubleSided?"#define DOUBLE_SIDED":"",n.flipSided?"#define FLIP_SIDED":"",n.shadowMapEnabled?"#define USE_SHADOWMAP":"",n.shadowMapEnabled?"#define "+l:"",n.premultipliedAlpha?"#define PREMULTIPLIED_ALPHA":"",n.numLightProbes>0?"#define USE_LIGHT_PROBES":"",n.decodeVideoTexture?"#define DECODE_VIDEO_TEXTURE":"",n.decodeVideoTextureEmissive?"#define DECODE_VIDEO_TEXTURE_EMISSIVE":"",n.logarithmicDepthBuffer?"#define USE_LOGARITHMIC_DEPTH_BUFFER":"",n.reversedDepthBuffer?"#define USE_REVERSED_DEPTH_BUFFER":"","uniform mat4 viewMatrix;","uniform vec3 cameraPosition;","uniform bool isOrthographic;",n.toneMapping!==Rr?"#define TONE_MAPPING":"",n.toneMapping!==Rr?je.tonemapping_pars_fragment:"",n.toneMapping!==Rr?ab("toneMapping",n.toneMapping):"",n.dithering?"#define DITHERING":"",n.opaque?"#define OPAQUE":"",je.colorspace_pars_fragment,sb("linearToOutputTexel",n.outputColorSpace),ub(),n.useDepthPacking?"#define DEPTH_PACKING "+n.depthPacking:"",`
`].filter(Ks).join(`
`)),s=zh(s),s=Cg(s,n),s=Tg(s,n),a=zh(a),a=Cg(a,n),a=Tg(a,n),s=Rg(s),a=Rg(a),n.isRawShaderMaterial!==!0&&(b=`#version 300 es
`,g=[d,"#define attribute in","#define varying out","#define texture2D texture"].join(`
`)+`
`+g,m=["#define varying in",n.glslVersion===Mh?"":"layout(location = 0) out highp vec4 pc_fragColor;",n.glslVersion===Mh?"":"#define gl_FragColor pc_fragColor","#define gl_FragDepthEXT gl_FragDepth","#define texture2D texture","#define textureCube texture","#define texture2DProj textureProj","#define texture2DLodEXT textureLod","#define texture2DProjLodEXT textureProjLod","#define textureCubeLodEXT textureLod","#define texture2DGradEXT textureGrad","#define texture2DProjGradEXT textureProjGrad","#define textureCubeGradEXT textureGrad"].join(`
`)+`
`+m);let v=b+g+s,_=b+m+a,M=Eg(i,i.VERTEX_SHADER,v),y=Eg(i,i.FRAGMENT_SHADER,_);i.attachShader(p,M),i.attachShader(p,y),n.index0AttributeName!==void 0?i.bindAttribLocation(p,0,n.index0AttributeName):n.morphTargets===!0&&i.bindAttribLocation(p,0,"position"),i.linkProgram(p);function E(C){if(t.debug.checkShaderErrors){let F=i.getProgramInfoLog(p)||"",O=i.getShaderInfoLog(M)||"",U=i.getShaderInfoLog(y)||"",z=F.trim(),B=O.trim(),J=U.trim(),H=!0,ne=!0;if(i.getProgramParameter(p,i.LINK_STATUS)===!1)if(H=!1,typeof t.debug.onShaderError=="function")t.debug.onShaderError(i,p,M,y);else{let se=Ag(i,M,"vertex"),ge=Ag(i,y,"fragment");console.error("THREE.WebGLProgram: Shader Error "+i.getError()+" - VALIDATE_STATUS "+i.getProgramParameter(p,i.VALIDATE_STATUS)+`

Material Name: `+C.name+`
Material Type: `+C.type+`

Program Info Log: `+z+`
`+se+`
`+ge)}else z!==""?console.warn("THREE.WebGLProgram: Program Info Log:",z):(B===""||J==="")&&(ne=!1);ne&&(C.diagnostics={runnable:H,programLog:z,vertexShader:{log:B,prefix:g},fragmentShader:{log:J,prefix:m}})}i.deleteShader(M),i.deleteShader(y),D=new Vo(i,p),S=fb(i,p)}let D;this.getUniforms=function(){return D===void 0&&E(this),D};let S;this.getAttributes=function(){return S===void 0&&E(this),S};let w=n.rendererExtensionParallelShaderCompile===!1;return this.isReady=function(){return w===!1&&(w=i.getProgramParameter(p,nb)),w},this.destroy=function(){r.releaseStatesOfProgram(this),i.deleteProgram(p),this.program=void 0},this.type=n.shaderType,this.name=n.shaderName,this.id=rb++,this.cacheKey=e,this.usedTimes=1,this.program=p,this.vertexShader=M,this.fragmentShader=y,this}var wb=0,kh=class{constructor(){this.shaderCache=new Map,this.materialCache=new Map}update(e){let n=e.vertexShader,r=e.fragmentShader,i=this._getShaderStage(n),o=this._getShaderStage(r),s=this._getShaderCacheForMaterial(e);return s.has(i)===!1&&(s.add(i),i.usedTimes++),s.has(o)===!1&&(s.add(o),o.usedTimes++),this}remove(e){let n=this.materialCache.get(e);for(let r of n)r.usedTimes--,r.usedTimes===0&&this.shaderCache.delete(r.code);return this.materialCache.delete(e),this}getVertexShaderID(e){return this._getShaderStage(e.vertexShader).id}getFragmentShaderID(e){return this._getShaderStage(e.fragmentShader).id}dispose(){this.shaderCache.clear(),this.materialCache.clear()}_getShaderCacheForMaterial(e){let n=this.materialCache,r=n.get(e);return r===void 0&&(r=new Set,n.set(e,r)),r}_getShaderStage(e){let n=this.shaderCache,r=n.get(e);return r===void 0&&(r=new Vh(e),n.set(e,r)),r}},Vh=class{constructor(e){this.id=wb++,this.code=e,this.usedTimes=0}};function bb(t,e,n,r,i,o,s){let a=new Es,l=new kh,u=new Set,c=[],f=i.logarithmicDepthBuffer,h=i.vertexTextures,d=i.precision,x={MeshDepthMaterial:"depth",MeshDistanceMaterial:"distanceRGBA",MeshNormalMaterial:"normal",MeshBasicMaterial:"basic",MeshLambertMaterial:"lambert",MeshPhongMaterial:"phong",MeshToonMaterial:"toon",MeshStandardMaterial:"physical",MeshPhysicalMaterial:"physical",MeshMatcapMaterial:"matcap",LineBasicMaterial:"basic",LineDashedMaterial:"dashed",PointsMaterial:"points",ShadowMaterial:"shadow",SpriteMaterial:"sprite"};function p(S){return u.add(S),S===0?"uv":`uv${S}`}function g(S,w,C,F,O){let U=F.fog,z=O.geometry,B=S.isMeshStandardMaterial?F.environment:null,J=(S.isMeshStandardMaterial?n:e).get(S.envMap||B),H=J&&J.mapping===qs?J.image.height:null,ne=x[S.type];S.precision!==null&&(d=i.getMaxPrecision(S.precision),d!==S.precision&&console.warn("THREE.WebGLProgram.getParameters:",S.precision,"not supported, using",d,"instead."));let se=z.morphAttributes.position||z.morphAttributes.normal||z.morphAttributes.color,ge=se!==void 0?se.length:0,Te=0;z.morphAttributes.position!==void 0&&(Te=1),z.morphAttributes.normal!==void 0&&(Te=2),z.morphAttributes.color!==void 0&&(Te=3);let ze,Ze,ke,re;if(ne){let nt=dr[ne];ze=nt.vertexShader,Ze=nt.fragmentShader}else ze=S.vertexShader,Ze=S.fragmentShader,l.update(S),ke=l.getVertexShaderID(S),re=l.getFragmentShaderID(S);let ae=t.getRenderTarget(),Se=t.state.buffers.depth.getReversed(),De=O.isInstancedMesh===!0,xe=O.isBatchedMesh===!0,Xe=!!S.map,ut=!!S.matcap,N=!!J,Je=!!S.aoMap,Ne=!!S.lightMap,Be=!!S.bumpMap,Ae=!!S.normalMap,pt=!!S.displacementMap,Fe=!!S.emissiveMap,$e=!!S.metalnessMap,It=!!S.roughnessMap,Et=S.anisotropy>0,P=S.clearcoat>0,A=S.dispersion>0,Z=S.iridescence>0,le=S.sheen>0,de=S.transmission>0,oe=Et&&!!S.anisotropyMap,R=P&&!!S.clearcoatMap,I=P&&!!S.clearcoatNormalMap,V=P&&!!S.clearcoatRoughnessMap,X=Z&&!!S.iridescenceMap,G=Z&&!!S.iridescenceThicknessMap,W=le&&!!S.sheenColorMap,ie=le&&!!S.sheenRoughnessMap,$=!!S.specularMap,ee=!!S.specularColorMap,Q=!!S.specularIntensityMap,L=de&&!!S.transmissionMap,ce=de&&!!S.thicknessMap,pe=!!S.gradientMap,_e=!!S.alphaMap,fe=S.alphaTest>0,ue=!!S.alphaHash,Ee=!!S.extensions,We=Rr;S.toneMapped&&(ae===null||ae.isXRRenderTarget===!0)&&(We=t.toneMapping);let mt={shaderID:ne,shaderType:S.type,shaderName:S.name,vertexShader:ze,fragmentShader:Ze,defines:S.defines,customVertexShaderID:ke,customFragmentShaderID:re,isRawShaderMaterial:S.isRawShaderMaterial===!0,glslVersion:S.glslVersion,precision:d,batching:xe,batchingColor:xe&&O._colorsTexture!==null,instancing:De,instancingColor:De&&O.instanceColor!==null,instancingMorph:De&&O.morphTexture!==null,supportsVertexTextures:h,outputColorSpace:ae===null?t.outputColorSpace:ae.isXRRenderTarget===!0?ae.texture.colorSpace:Ai,alphaToCoverage:!!S.alphaToCoverage,map:Xe,matcap:ut,envMap:N,envMapMode:N&&J.mapping,envMapCubeUVHeight:H,aoMap:Je,lightMap:Ne,bumpMap:Be,normalMap:Ae,displacementMap:h&&pt,emissiveMap:Fe,normalMapObjectSpace:Ae&&S.normalMapType===jm,normalMapTangentSpace:Ae&&S.normalMapType===_h,metalnessMap:$e,roughnessMap:It,anisotropy:Et,anisotropyMap:oe,clearcoat:P,clearcoatMap:R,clearcoatNormalMap:I,clearcoatRoughnessMap:V,dispersion:A,iridescence:Z,iridescenceMap:X,iridescenceThicknessMap:G,sheen:le,sheenColorMap:W,sheenRoughnessMap:ie,specularMap:$,specularColorMap:ee,specularIntensityMap:Q,transmission:de,transmissionMap:L,thicknessMap:ce,gradientMap:pe,opaque:S.transparent===!1&&S.blending===Ei&&S.alphaToCoverage===!1,alphaMap:_e,alphaTest:fe,alphaHash:ue,combine:S.combine,mapUv:Xe&&p(S.map.channel),aoMapUv:Je&&p(S.aoMap.channel),lightMapUv:Ne&&p(S.lightMap.channel),bumpMapUv:Be&&p(S.bumpMap.channel),normalMapUv:Ae&&p(S.normalMap.channel),displacementMapUv:pt&&p(S.displacementMap.channel),emissiveMapUv:Fe&&p(S.emissiveMap.channel),metalnessMapUv:$e&&p(S.metalnessMap.channel),roughnessMapUv:It&&p(S.roughnessMap.channel),anisotropyMapUv:oe&&p(S.anisotropyMap.channel),clearcoatMapUv:R&&p(S.clearcoatMap.channel),clearcoatNormalMapUv:I&&p(S.clearcoatNormalMap.channel),clearcoatRoughnessMapUv:V&&p(S.clearcoatRoughnessMap.channel),iridescenceMapUv:X&&p(S.iridescenceMap.channel),iridescenceThicknessMapUv:G&&p(S.iridescenceThicknessMap.channel),sheenColorMapUv:W&&p(S.sheenColorMap.channel),sheenRoughnessMapUv:ie&&p(S.sheenRoughnessMap.channel),specularMapUv:$&&p(S.specularMap.channel),specularColorMapUv:ee&&p(S.specularColorMap.channel),specularIntensityMapUv:Q&&p(S.specularIntensityMap.channel),transmissionMapUv:L&&p(S.transmissionMap.channel),thicknessMapUv:ce&&p(S.thicknessMap.channel),alphaMapUv:_e&&p(S.alphaMap.channel),vertexTangents:!!z.attributes.tangent&&(Ae||Et),vertexColors:S.vertexColors,vertexAlphas:S.vertexColors===!0&&!!z.attributes.color&&z.attributes.color.itemSize===4,pointsUvs:O.isPoints===!0&&!!z.attributes.uv&&(Xe||_e),fog:!!U,useFog:S.fog===!0,fogExp2:!!U&&U.isFogExp2,flatShading:S.flatShading===!0&&S.wireframe===!1,sizeAttenuation:S.sizeAttenuation===!0,logarithmicDepthBuffer:f,reversedDepthBuffer:Se,skinning:O.isSkinnedMesh===!0,morphTargets:z.morphAttributes.position!==void 0,morphNormals:z.morphAttributes.normal!==void 0,morphColors:z.morphAttributes.color!==void 0,morphTargetsCount:ge,morphTextureStride:Te,numDirLights:w.directional.length,numPointLights:w.point.length,numSpotLights:w.spot.length,numSpotLightMaps:w.spotLightMap.length,numRectAreaLights:w.rectArea.length,numHemiLights:w.hemi.length,numDirLightShadows:w.directionalShadowMap.length,numPointLightShadows:w.pointShadowMap.length,numSpotLightShadows:w.spotShadowMap.length,numSpotLightShadowsWithMaps:w.numSpotLightShadowsWithMaps,numLightProbes:w.numLightProbes,numClippingPlanes:s.numPlanes,numClipIntersection:s.numIntersection,dithering:S.dithering,shadowMapEnabled:t.shadowMap.enabled&&C.length>0,shadowMapType:t.shadowMap.type,toneMapping:We,decodeVideoTexture:Xe&&S.map.isVideoTexture===!0&&ct.getTransfer(S.map.colorSpace)===gt,decodeVideoTextureEmissive:Fe&&S.emissiveMap.isVideoTexture===!0&&ct.getTransfer(S.emissiveMap.colorSpace)===gt,premultipliedAlpha:S.premultipliedAlpha,doubleSided:S.side===fr,flipSided:S.side===fn,useDepthPacking:S.depthPacking>=0,depthPacking:S.depthPacking||0,index0AttributeName:S.index0AttributeName,extensionClipCullDistance:Ee&&S.extensions.clipCullDistance===!0&&r.has("WEBGL_clip_cull_distance"),extensionMultiDraw:(Ee&&S.extensions.multiDraw===!0||xe)&&r.has("WEBGL_multi_draw"),rendererExtensionParallelShaderCompile:r.has("KHR_parallel_shader_compile"),customProgramCacheKey:S.customProgramCacheKey()};return mt.vertexUv1s=u.has(1),mt.vertexUv2s=u.has(2),mt.vertexUv3s=u.has(3),u.clear(),mt}function m(S){let w=[];if(S.shaderID?w.push(S.shaderID):(w.push(S.customVertexShaderID),w.push(S.customFragmentShaderID)),S.defines!==void 0)for(let C in S.defines)w.push(C),w.push(S.defines[C]);return S.isRawShaderMaterial===!1&&(b(w,S),v(w,S),w.push(t.outputColorSpace)),w.push(S.customProgramCacheKey),w.join()}function b(S,w){S.push(w.precision),S.push(w.outputColorSpace),S.push(w.envMapMode),S.push(w.envMapCubeUVHeight),S.push(w.mapUv),S.push(w.alphaMapUv),S.push(w.lightMapUv),S.push(w.aoMapUv),S.push(w.bumpMapUv),S.push(w.normalMapUv),S.push(w.displacementMapUv),S.push(w.emissiveMapUv),S.push(w.metalnessMapUv),S.push(w.roughnessMapUv),S.push(w.anisotropyMapUv),S.push(w.clearcoatMapUv),S.push(w.clearcoatNormalMapUv),S.push(w.clearcoatRoughnessMapUv),S.push(w.iridescenceMapUv),S.push(w.iridescenceThicknessMapUv),S.push(w.sheenColorMapUv),S.push(w.sheenRoughnessMapUv),S.push(w.specularMapUv),S.push(w.specularColorMapUv),S.push(w.specularIntensityMapUv),S.push(w.transmissionMapUv),S.push(w.thicknessMapUv),S.push(w.combine),S.push(w.fogExp2),S.push(w.sizeAttenuation),S.push(w.morphTargetsCount),S.push(w.morphAttributeCount),S.push(w.numDirLights),S.push(w.numPointLights),S.push(w.numSpotLights),S.push(w.numSpotLightMaps),S.push(w.numHemiLights),S.push(w.numRectAreaLights),S.push(w.numDirLightShadows),S.push(w.numPointLightShadows),S.push(w.numSpotLightShadows),S.push(w.numSpotLightShadowsWithMaps),S.push(w.numLightProbes),S.push(w.shadowMapType),S.push(w.toneMapping),S.push(w.numClippingPlanes),S.push(w.numClipIntersection),S.push(w.depthPacking)}function v(S,w){a.disableAll(),w.supportsVertexTextures&&a.enable(0),w.instancing&&a.enable(1),w.instancingColor&&a.enable(2),w.instancingMorph&&a.enable(3),w.matcap&&a.enable(4),w.envMap&&a.enable(5),w.normalMapObjectSpace&&a.enable(6),w.normalMapTangentSpace&&a.enable(7),w.clearcoat&&a.enable(8),w.iridescence&&a.enable(9),w.alphaTest&&a.enable(10),w.vertexColors&&a.enable(11),w.vertexAlphas&&a.enable(12),w.vertexUv1s&&a.enable(13),w.vertexUv2s&&a.enable(14),w.vertexUv3s&&a.enable(15),w.vertexTangents&&a.enable(16),w.anisotropy&&a.enable(17),w.alphaHash&&a.enable(18),w.batching&&a.enable(19),w.dispersion&&a.enable(20),w.batchingColor&&a.enable(21),w.gradientMap&&a.enable(22),S.push(a.mask),a.disableAll(),w.fog&&a.enable(0),w.useFog&&a.enable(1),w.flatShading&&a.enable(2),w.logarithmicDepthBuffer&&a.enable(3),w.reversedDepthBuffer&&a.enable(4),w.skinning&&a.enable(5),w.morphTargets&&a.enable(6),w.morphNormals&&a.enable(7),w.morphColors&&a.enable(8),w.premultipliedAlpha&&a.enable(9),w.shadowMapEnabled&&a.enable(10),w.doubleSided&&a.enable(11),w.flipSided&&a.enable(12),w.useDepthPacking&&a.enable(13),w.dithering&&a.enable(14),w.transmission&&a.enable(15),w.sheen&&a.enable(16),w.opaque&&a.enable(17),w.pointsUvs&&a.enable(18),w.decodeVideoTexture&&a.enable(19),w.decodeVideoTextureEmissive&&a.enable(20),w.alphaToCoverage&&a.enable(21),S.push(a.mask)}function _(S){let w=x[S.type],C;if(w){let F=dr[w];C=cg.clone(F.uniforms)}else C=S.uniforms;return C}function M(S,w){let C;for(let F=0,O=c.length;F<O;F++){let U=c[F];if(U.cacheKey===w){C=U,++C.usedTimes;break}}return C===void 0&&(C=new Sb(t,w,S,o),c.push(C)),C}function y(S){if(--S.usedTimes===0){let w=c.indexOf(S);c[w]=c[c.length-1],c.pop(),S.destroy()}}function E(S){l.remove(S)}function D(){l.dispose()}return{getParameters:g,getProgramCacheKey:m,getUniforms:_,acquireProgram:M,releaseProgram:y,releaseShaderCache:E,programs:c,dispose:D}}function Eb(){let t=new WeakMap;function e(s){return t.has(s)}function n(s){let a=t.get(s);return a===void 0&&(a={},t.set(s,a)),a}function r(s){t.delete(s)}function i(s,a,l){t.get(s)[a]=l}function o(){t=new WeakMap}return{has:e,get:n,remove:r,update:i,dispose:o}}function Db(t,e){return t.groupOrder!==e.groupOrder?t.groupOrder-e.groupOrder:t.renderOrder!==e.renderOrder?t.renderOrder-e.renderOrder:t.material.id!==e.material.id?t.material.id-e.material.id:t.z!==e.z?t.z-e.z:t.id-e.id}function Pg(t,e){return t.groupOrder!==e.groupOrder?t.groupOrder-e.groupOrder:t.renderOrder!==e.renderOrder?t.renderOrder-e.renderOrder:t.z!==e.z?e.z-t.z:t.id-e.id}function Ig(){let t=[],e=0,n=[],r=[],i=[];function o(){e=0,n.length=0,r.length=0,i.length=0}function s(f,h,d,x,p,g){let m=t[e];return m===void 0?(m={id:f.id,object:f,geometry:h,material:d,groupOrder:x,renderOrder:f.renderOrder,z:p,group:g},t[e]=m):(m.id=f.id,m.object=f,m.geometry=h,m.material=d,m.groupOrder=x,m.renderOrder=f.renderOrder,m.z=p,m.group=g),e++,m}function a(f,h,d,x,p,g){let m=s(f,h,d,x,p,g);d.transmission>0?r.push(m):d.transparent===!0?i.push(m):n.push(m)}function l(f,h,d,x,p,g){let m=s(f,h,d,x,p,g);d.transmission>0?r.unshift(m):d.transparent===!0?i.unshift(m):n.unshift(m)}function u(f,h){n.length>1&&n.sort(f||Db),r.length>1&&r.sort(h||Pg),i.length>1&&i.sort(h||Pg)}function c(){for(let f=e,h=t.length;f<h;f++){let d=t[f];if(d.id===null)break;d.id=null,d.object=null,d.geometry=null,d.material=null,d.group=null}}return{opaque:n,transmissive:r,transparent:i,init:o,push:a,unshift:l,finish:c,sort:u}}function Ab(){let t=new WeakMap;function e(r,i){let o=t.get(r),s;return o===void 0?(s=new Ig,t.set(r,[s])):i>=o.length?(s=new Ig,o.push(s)):s=o[i],s}function n(){t=new WeakMap}return{get:e,dispose:n}}function Cb(){let t={};return{get:function(e){if(t[e.id]!==void 0)return t[e.id];let n;switch(e.type){case"DirectionalLight":n={direction:new k,color:new it};break;case"SpotLight":n={position:new k,direction:new k,color:new it,distance:0,coneCos:0,penumbraCos:0,decay:0};break;case"PointLight":n={position:new k,color:new it,distance:0,decay:0};break;case"HemisphereLight":n={direction:new k,skyColor:new it,groundColor:new it};break;case"RectAreaLight":n={color:new it,position:new k,halfWidth:new k,halfHeight:new k};break}return t[e.id]=n,n}}}function Tb(){let t={};return{get:function(e){if(t[e.id]!==void 0)return t[e.id];let n;switch(e.type){case"DirectionalLight":n={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new Ie};break;case"SpotLight":n={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new Ie};break;case"PointLight":n={shadowIntensity:1,shadowBias:0,shadowNormalBias:0,shadowRadius:1,shadowMapSize:new Ie,shadowCameraNear:1,shadowCameraFar:1e3};break}return t[e.id]=n,n}}}var Rb=0;function Fb(t,e){return(e.castShadow?2:0)-(t.castShadow?2:0)+(e.map?1:0)-(t.map?1:0)}function Pb(t){let e=new Cb,n=Tb(),r={version:0,hash:{directionalLength:-1,pointLength:-1,spotLength:-1,rectAreaLength:-1,hemiLength:-1,numDirectionalShadows:-1,numPointShadows:-1,numSpotShadows:-1,numSpotMaps:-1,numLightProbes:-1},ambient:[0,0,0],probe:[],directional:[],directionalShadow:[],directionalShadowMap:[],directionalShadowMatrix:[],spot:[],spotLightMap:[],spotShadow:[],spotShadowMap:[],spotLightMatrix:[],rectArea:[],rectAreaLTC1:null,rectAreaLTC2:null,point:[],pointShadow:[],pointShadowMap:[],pointShadowMatrix:[],hemi:[],numSpotLightShadowsWithMaps:0,numLightProbes:0};for(let u=0;u<9;u++)r.probe.push(new k);let i=new k,o=new Rt,s=new Rt;function a(u){let c=0,f=0,h=0;for(let S=0;S<9;S++)r.probe[S].set(0,0,0);let d=0,x=0,p=0,g=0,m=0,b=0,v=0,_=0,M=0,y=0,E=0;u.sort(Fb);for(let S=0,w=u.length;S<w;S++){let C=u[S],F=C.color,O=C.intensity,U=C.distance,z=C.shadow&&C.shadow.map?C.shadow.map.texture:null;if(C.isAmbientLight)c+=F.r*O,f+=F.g*O,h+=F.b*O;else if(C.isLightProbe){for(let B=0;B<9;B++)r.probe[B].addScaledVector(C.sh.coefficients[B],O);E++}else if(C.isDirectionalLight){let B=e.get(C);if(B.color.copy(C.color).multiplyScalar(C.intensity),C.castShadow){let J=C.shadow,H=n.get(C);H.shadowIntensity=J.intensity,H.shadowBias=J.bias,H.shadowNormalBias=J.normalBias,H.shadowRadius=J.radius,H.shadowMapSize=J.mapSize,r.directionalShadow[d]=H,r.directionalShadowMap[d]=z,r.directionalShadowMatrix[d]=C.shadow.matrix,b++}r.directional[d]=B,d++}else if(C.isSpotLight){let B=e.get(C);B.position.setFromMatrixPosition(C.matrixWorld),B.color.copy(F).multiplyScalar(O),B.distance=U,B.coneCos=Math.cos(C.angle),B.penumbraCos=Math.cos(C.angle*(1-C.penumbra)),B.decay=C.decay,r.spot[p]=B;let J=C.shadow;if(C.map&&(r.spotLightMap[M]=C.map,M++,J.updateMatrices(C),C.castShadow&&y++),r.spotLightMatrix[p]=J.matrix,C.castShadow){let H=n.get(C);H.shadowIntensity=J.intensity,H.shadowBias=J.bias,H.shadowNormalBias=J.normalBias,H.shadowRadius=J.radius,H.shadowMapSize=J.mapSize,r.spotShadow[p]=H,r.spotShadowMap[p]=z,_++}p++}else if(C.isRectAreaLight){let B=e.get(C);B.color.copy(F).multiplyScalar(O),B.halfWidth.set(C.width*.5,0,0),B.halfHeight.set(0,C.height*.5,0),r.rectArea[g]=B,g++}else if(C.isPointLight){let B=e.get(C);if(B.color.copy(C.color).multiplyScalar(C.intensity),B.distance=C.distance,B.decay=C.decay,C.castShadow){let J=C.shadow,H=n.get(C);H.shadowIntensity=J.intensity,H.shadowBias=J.bias,H.shadowNormalBias=J.normalBias,H.shadowRadius=J.radius,H.shadowMapSize=J.mapSize,H.shadowCameraNear=J.camera.near,H.shadowCameraFar=J.camera.far,r.pointShadow[x]=H,r.pointShadowMap[x]=z,r.pointShadowMatrix[x]=C.shadow.matrix,v++}r.point[x]=B,x++}else if(C.isHemisphereLight){let B=e.get(C);B.skyColor.copy(C.color).multiplyScalar(O),B.groundColor.copy(C.groundColor).multiplyScalar(O),r.hemi[m]=B,m++}}g>0&&(t.has("OES_texture_float_linear")===!0?(r.rectAreaLTC1=we.LTC_FLOAT_1,r.rectAreaLTC2=we.LTC_FLOAT_2):(r.rectAreaLTC1=we.LTC_HALF_1,r.rectAreaLTC2=we.LTC_HALF_2)),r.ambient[0]=c,r.ambient[1]=f,r.ambient[2]=h;let D=r.hash;(D.directionalLength!==d||D.pointLength!==x||D.spotLength!==p||D.rectAreaLength!==g||D.hemiLength!==m||D.numDirectionalShadows!==b||D.numPointShadows!==v||D.numSpotShadows!==_||D.numSpotMaps!==M||D.numLightProbes!==E)&&(r.directional.length=d,r.spot.length=p,r.rectArea.length=g,r.point.length=x,r.hemi.length=m,r.directionalShadow.length=b,r.directionalShadowMap.length=b,r.pointShadow.length=v,r.pointShadowMap.length=v,r.spotShadow.length=_,r.spotShadowMap.length=_,r.directionalShadowMatrix.length=b,r.pointShadowMatrix.length=v,r.spotLightMatrix.length=_+M-y,r.spotLightMap.length=M,r.numSpotLightShadowsWithMaps=y,r.numLightProbes=E,D.directionalLength=d,D.pointLength=x,D.spotLength=p,D.rectAreaLength=g,D.hemiLength=m,D.numDirectionalShadows=b,D.numPointShadows=v,D.numSpotShadows=_,D.numSpotMaps=M,D.numLightProbes=E,r.version=Rb++)}function l(u,c){let f=0,h=0,d=0,x=0,p=0,g=c.matrixWorldInverse;for(let m=0,b=u.length;m<b;m++){let v=u[m];if(v.isDirectionalLight){let _=r.directional[f];_.direction.setFromMatrixPosition(v.matrixWorld),i.setFromMatrixPosition(v.target.matrixWorld),_.direction.sub(i),_.direction.transformDirection(g),f++}else if(v.isSpotLight){let _=r.spot[d];_.position.setFromMatrixPosition(v.matrixWorld),_.position.applyMatrix4(g),_.direction.setFromMatrixPosition(v.matrixWorld),i.setFromMatrixPosition(v.target.matrixWorld),_.direction.sub(i),_.direction.transformDirection(g),d++}else if(v.isRectAreaLight){let _=r.rectArea[x];_.position.setFromMatrixPosition(v.matrixWorld),_.position.applyMatrix4(g),s.identity(),o.copy(v.matrixWorld),o.premultiply(g),s.extractRotation(o),_.halfWidth.set(v.width*.5,0,0),_.halfHeight.set(0,v.height*.5,0),_.halfWidth.applyMatrix4(s),_.halfHeight.applyMatrix4(s),x++}else if(v.isPointLight){let _=r.point[h];_.position.setFromMatrixPosition(v.matrixWorld),_.position.applyMatrix4(g),h++}else if(v.isHemisphereLight){let _=r.hemi[p];_.direction.setFromMatrixPosition(v.matrixWorld),_.direction.transformDirection(g),p++}}}return{setup:a,setupView:l,state:r}}function Ng(t){let e=new Pb(t),n=[],r=[];function i(c){u.camera=c,n.length=0,r.length=0}function o(c){n.push(c)}function s(c){r.push(c)}function a(){e.setup(n)}function l(c){e.setupView(n,c)}let u={lightsArray:n,shadowsArray:r,camera:null,lights:e,transmissionRenderTarget:{}};return{init:i,state:u,setupLights:a,setupLightsView:l,pushLight:o,pushShadow:s}}function Ib(t){let e=new WeakMap;function n(i,o=0){let s=e.get(i),a;return s===void 0?(a=new Ng(t),e.set(i,[a])):o>=s.length?(a=new Ng(t),s.push(a)):a=s[o],a}function r(){e=new WeakMap}return{get:n,dispose:r}}var Nb=`void main() {
	gl_Position = vec4( position, 1.0 );
}`,Lb=`uniform sampler2D shadow_pass;
uniform vec2 resolution;
uniform float radius;
#include <packing>
void main() {
	const float samples = float( VSM_SAMPLES );
	float mean = 0.0;
	float squared_mean = 0.0;
	float uvStride = samples <= 1.0 ? 0.0 : 2.0 / ( samples - 1.0 );
	float uvStart = samples <= 1.0 ? 0.0 : - 1.0;
	for ( float i = 0.0; i < samples; i ++ ) {
		float uvOffset = uvStart + i * uvStride;
		#ifdef HORIZONTAL_PASS
			vec2 distribution = unpackRGBATo2Half( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( uvOffset, 0.0 ) * radius ) / resolution ) );
			mean += distribution.x;
			squared_mean += distribution.y * distribution.y + distribution.x * distribution.x;
		#else
			float depth = unpackRGBAToDepth( texture2D( shadow_pass, ( gl_FragCoord.xy + vec2( 0.0, uvOffset ) * radius ) / resolution ) );
			mean += depth;
			squared_mean += depth * depth;
		#endif
	}
	mean = mean / samples;
	squared_mean = squared_mean / samples;
	float std_dev = sqrt( squared_mean - mean * mean );
	gl_FragColor = pack2HalfToRGBA( vec2( mean, std_dev ) );
}`;function Bb(t,e,n){let r=new To,i=new Ie,o=new Ie,s=new Ft,a=new wu({depthPacking:Qm}),l=new bu,u={},c=n.maxTextureSize,f={[Ar]:fn,[fn]:Ar,[fr]:fr},h=new jn({defines:{VSM_SAMPLES:8},uniforms:{shadow_pass:{value:null},resolution:{value:new Ie},radius:{value:4}},vertexShader:Nb,fragmentShader:Lb}),d=h.clone();d.defines.HORIZONTAL_PASS=1;let x=new cn;x.setAttribute("position",new Cn(new Float32Array([-1,-1,.5,3,-1,.5,-1,3,.5]),3));let p=new Lt(x,h),g=this;this.enabled=!1,this.autoUpdate=!0,this.needsUpdate=!1,this.type=oh;let m=this.type;this.render=function(y,E,D){if(g.enabled===!1||g.autoUpdate===!1&&g.needsUpdate===!1||y.length===0)return;let S=t.getRenderTarget(),w=t.getActiveCubeFace(),C=t.getActiveMipmapLevel(),F=t.state;F.setBlending(Tr),F.buffers.depth.getReversed()===!0?F.buffers.color.setClear(0,0,0,0):F.buffers.color.setClear(1,1,1,1),F.buffers.depth.setTest(!0),F.setScissorTest(!1);let O=m!==cr&&this.type===cr,U=m===cr&&this.type!==cr;for(let z=0,B=y.length;z<B;z++){let J=y[z],H=J.shadow;if(H===void 0){console.warn("THREE.WebGLShadowMap:",J,"has no shadow.");continue}if(H.autoUpdate===!1&&H.needsUpdate===!1)continue;i.copy(H.mapSize);let ne=H.getFrameExtents();if(i.multiply(ne),o.copy(H.mapSize),(i.x>c||i.y>c)&&(i.x>c&&(o.x=Math.floor(c/ne.x),i.x=o.x*ne.x,H.mapSize.x=o.x),i.y>c&&(o.y=Math.floor(c/ne.y),i.y=o.y*ne.y,H.mapSize.y=o.y)),H.map===null||O===!0||U===!0){let ge=this.type!==cr?{minFilter:zn,magFilter:zn}:{};H.map!==null&&H.map.dispose(),H.map=new lr(i.x,i.y,ge),H.map.texture.name=J.name+".shadowMap",H.camera.updateProjectionMatrix()}t.setRenderTarget(H.map),t.clear();let se=H.getViewportCount();for(let ge=0;ge<se;ge++){let Te=H.getViewport(ge);s.set(o.x*Te.x,o.y*Te.y,o.x*Te.z,o.y*Te.w),F.viewport(s),H.updateMatrices(J,ge),r=H.getFrustum(),_(E,D,H.camera,J,this.type)}H.isPointLightShadow!==!0&&this.type===cr&&b(H,D),H.needsUpdate=!1}m=this.type,g.needsUpdate=!1,t.setRenderTarget(S,w,C)};function b(y,E){let D=e.update(p);h.defines.VSM_SAMPLES!==y.blurSamples&&(h.defines.VSM_SAMPLES=y.blurSamples,d.defines.VSM_SAMPLES=y.blurSamples,h.needsUpdate=!0,d.needsUpdate=!0),y.mapPass===null&&(y.mapPass=new lr(i.x,i.y)),h.uniforms.shadow_pass.value=y.map.texture,h.uniforms.resolution.value=y.mapSize,h.uniforms.radius.value=y.radius,t.setRenderTarget(y.mapPass),t.clear(),t.renderBufferDirect(E,null,D,h,p,null),d.uniforms.shadow_pass.value=y.mapPass.texture,d.uniforms.resolution.value=y.mapSize,d.uniforms.radius.value=y.radius,t.setRenderTarget(y.map),t.clear(),t.renderBufferDirect(E,null,D,d,p,null)}function v(y,E,D,S){let w=null,C=D.isPointLight===!0?y.customDistanceMaterial:y.customDepthMaterial;if(C!==void 0)w=C;else if(w=D.isPointLight===!0?l:a,t.localClippingEnabled&&E.clipShadows===!0&&Array.isArray(E.clippingPlanes)&&E.clippingPlanes.length!==0||E.displacementMap&&E.displacementScale!==0||E.alphaMap&&E.alphaTest>0||E.map&&E.alphaTest>0||E.alphaToCoverage===!0){let F=w.uuid,O=E.uuid,U=u[F];U===void 0&&(U={},u[F]=U);let z=U[O];z===void 0&&(z=w.clone(),U[O]=z,E.addEventListener("dispose",M)),w=z}if(w.visible=E.visible,w.wireframe=E.wireframe,S===cr?w.side=E.shadowSide!==null?E.shadowSide:E.side:w.side=E.shadowSide!==null?E.shadowSide:f[E.side],w.alphaMap=E.alphaMap,w.alphaTest=E.alphaToCoverage===!0?.5:E.alphaTest,w.map=E.map,w.clipShadows=E.clipShadows,w.clippingPlanes=E.clippingPlanes,w.clipIntersection=E.clipIntersection,w.displacementMap=E.displacementMap,w.displacementScale=E.displacementScale,w.displacementBias=E.displacementBias,w.wireframeLinewidth=E.wireframeLinewidth,w.linewidth=E.linewidth,D.isPointLight===!0&&w.isMeshDistanceMaterial===!0){let F=t.properties.get(w);F.light=D}return w}function _(y,E,D,S,w){if(y.visible===!1)return;if(y.layers.test(E.layers)&&(y.isMesh||y.isLine||y.isPoints)&&(y.castShadow||y.receiveShadow&&w===cr)&&(!y.frustumCulled||r.intersectsObject(y))){y.modelViewMatrix.multiplyMatrices(D.matrixWorldInverse,y.matrixWorld);let O=e.update(y),U=y.material;if(Array.isArray(U)){let z=O.groups;for(let B=0,J=z.length;B<J;B++){let H=z[B],ne=U[H.materialIndex];if(ne&&ne.visible){let se=v(y,ne,S,w);y.onBeforeShadow(t,y,E,D,O,se,H),t.renderBufferDirect(D,null,O,se,y,H),y.onAfterShadow(t,y,E,D,O,se,H)}}}else if(U.visible){let z=v(y,U,S,w);y.onBeforeShadow(t,y,E,D,O,z,null),t.renderBufferDirect(D,null,O,z,y,null),y.onAfterShadow(t,y,E,D,O,z,null)}}let F=y.children;for(let O=0,U=F.length;O<U;O++)_(F[O],E,D,S,w)}function M(y){y.target.removeEventListener("dispose",M);for(let D in u){let S=u[D],w=y.target.uuid;w in S&&(S[w].dispose(),delete S[w])}}}var Ub={[Lu]:Bu,[Uu]:ku,[Ou]:Vu,[Di]:zu,[Bu]:Lu,[ku]:Uu,[Vu]:Ou,[zu]:Di};function Ob(t,e){function n(){let L=!1,ce=new Ft,pe=null,_e=new Ft(0,0,0,0);return{setMask:function(fe){pe!==fe&&!L&&(t.colorMask(fe,fe,fe,fe),pe=fe)},setLocked:function(fe){L=fe},setClear:function(fe,ue,Ee,We,mt){mt===!0&&(fe*=We,ue*=We,Ee*=We),ce.set(fe,ue,Ee,We),_e.equals(ce)===!1&&(t.clearColor(fe,ue,Ee,We),_e.copy(ce))},reset:function(){L=!1,pe=null,_e.set(-1,0,0,0)}}}function r(){let L=!1,ce=!1,pe=null,_e=null,fe=null;return{setReversed:function(ue){if(ce!==ue){let Ee=e.get("EXT_clip_control");ue?Ee.clipControlEXT(Ee.LOWER_LEFT_EXT,Ee.ZERO_TO_ONE_EXT):Ee.clipControlEXT(Ee.LOWER_LEFT_EXT,Ee.NEGATIVE_ONE_TO_ONE_EXT),ce=ue;let We=fe;fe=null,this.setClear(We)}},getReversed:function(){return ce},setTest:function(ue){ue?ae(t.DEPTH_TEST):Se(t.DEPTH_TEST)},setMask:function(ue){pe!==ue&&!L&&(t.depthMask(ue),pe=ue)},setFunc:function(ue){if(ce&&(ue=Ub[ue]),_e!==ue){switch(ue){case Lu:t.depthFunc(t.NEVER);break;case Bu:t.depthFunc(t.ALWAYS);break;case Uu:t.depthFunc(t.LESS);break;case Di:t.depthFunc(t.LEQUAL);break;case Ou:t.depthFunc(t.EQUAL);break;case zu:t.depthFunc(t.GEQUAL);break;case ku:t.depthFunc(t.GREATER);break;case Vu:t.depthFunc(t.NOTEQUAL);break;default:t.depthFunc(t.LEQUAL)}_e=ue}},setLocked:function(ue){L=ue},setClear:function(ue){fe!==ue&&(ce&&(ue=1-ue),t.clearDepth(ue),fe=ue)},reset:function(){L=!1,pe=null,_e=null,fe=null,ce=!1}}}function i(){let L=!1,ce=null,pe=null,_e=null,fe=null,ue=null,Ee=null,We=null,mt=null;return{setTest:function(nt){L||(nt?ae(t.STENCIL_TEST):Se(t.STENCIL_TEST))},setMask:function(nt){ce!==nt&&!L&&(t.stencilMask(nt),ce=nt)},setFunc:function(nt,pn,Nn){(pe!==nt||_e!==pn||fe!==Nn)&&(t.stencilFunc(nt,pn,Nn),pe=nt,_e=pn,fe=Nn)},setOp:function(nt,pn,Nn){(ue!==nt||Ee!==pn||We!==Nn)&&(t.stencilOp(nt,pn,Nn),ue=nt,Ee=pn,We=Nn)},setLocked:function(nt){L=nt},setClear:function(nt){mt!==nt&&(t.clearStencil(nt),mt=nt)},reset:function(){L=!1,ce=null,pe=null,_e=null,fe=null,ue=null,Ee=null,We=null,mt=null}}}let o=new n,s=new r,a=new i,l=new WeakMap,u=new WeakMap,c={},f={},h=new WeakMap,d=[],x=null,p=!1,g=null,m=null,b=null,v=null,_=null,M=null,y=null,E=new it(0,0,0),D=0,S=!1,w=null,C=null,F=null,O=null,U=null,z=t.getParameter(t.MAX_COMBINED_TEXTURE_IMAGE_UNITS),B=!1,J=0,H=t.getParameter(t.VERSION);H.indexOf("WebGL")!==-1?(J=parseFloat(/^WebGL (\d)/.exec(H)[1]),B=J>=1):H.indexOf("OpenGL ES")!==-1&&(J=parseFloat(/^OpenGL ES (\d)/.exec(H)[1]),B=J>=2);let ne=null,se={},ge=t.getParameter(t.SCISSOR_BOX),Te=t.getParameter(t.VIEWPORT),ze=new Ft().fromArray(ge),Ze=new Ft().fromArray(Te);function ke(L,ce,pe,_e){let fe=new Uint8Array(4),ue=t.createTexture();t.bindTexture(L,ue),t.texParameteri(L,t.TEXTURE_MIN_FILTER,t.NEAREST),t.texParameteri(L,t.TEXTURE_MAG_FILTER,t.NEAREST);for(let Ee=0;Ee<pe;Ee++)L===t.TEXTURE_3D||L===t.TEXTURE_2D_ARRAY?t.texImage3D(ce,0,t.RGBA,1,1,_e,0,t.RGBA,t.UNSIGNED_BYTE,fe):t.texImage2D(ce+Ee,0,t.RGBA,1,1,0,t.RGBA,t.UNSIGNED_BYTE,fe);return ue}let re={};re[t.TEXTURE_2D]=ke(t.TEXTURE_2D,t.TEXTURE_2D,1),re[t.TEXTURE_CUBE_MAP]=ke(t.TEXTURE_CUBE_MAP,t.TEXTURE_CUBE_MAP_POSITIVE_X,6),re[t.TEXTURE_2D_ARRAY]=ke(t.TEXTURE_2D_ARRAY,t.TEXTURE_2D_ARRAY,1,1),re[t.TEXTURE_3D]=ke(t.TEXTURE_3D,t.TEXTURE_3D,1,1),o.setClear(0,0,0,1),s.setClear(1),a.setClear(0),ae(t.DEPTH_TEST),s.setFunc(Di),Be(!1),Ae(ih),ae(t.CULL_FACE),Je(Tr);function ae(L){c[L]!==!0&&(t.enable(L),c[L]=!0)}function Se(L){c[L]!==!1&&(t.disable(L),c[L]=!1)}function De(L,ce){return f[L]!==ce?(t.bindFramebuffer(L,ce),f[L]=ce,L===t.DRAW_FRAMEBUFFER&&(f[t.FRAMEBUFFER]=ce),L===t.FRAMEBUFFER&&(f[t.DRAW_FRAMEBUFFER]=ce),!0):!1}function xe(L,ce){let pe=d,_e=!1;if(L){pe=h.get(ce),pe===void 0&&(pe=[],h.set(ce,pe));let fe=L.textures;if(pe.length!==fe.length||pe[0]!==t.COLOR_ATTACHMENT0){for(let ue=0,Ee=fe.length;ue<Ee;ue++)pe[ue]=t.COLOR_ATTACHMENT0+ue;pe.length=fe.length,_e=!0}}else pe[0]!==t.BACK&&(pe[0]=t.BACK,_e=!0);_e&&t.drawBuffers(pe)}function Xe(L){return x!==L?(t.useProgram(L),x=L,!0):!1}let ut={[$r]:t.FUNC_ADD,[bm]:t.FUNC_SUBTRACT,[Em]:t.FUNC_REVERSE_SUBTRACT};ut[Dm]=t.MIN,ut[Am]=t.MAX;let N={[Cm]:t.ZERO,[Tm]:t.ONE,[Rm]:t.SRC_COLOR,[nu]:t.SRC_ALPHA,[Bm]:t.SRC_ALPHA_SATURATE,[Nm]:t.DST_COLOR,[Pm]:t.DST_ALPHA,[Fm]:t.ONE_MINUS_SRC_COLOR,[ru]:t.ONE_MINUS_SRC_ALPHA,[Lm]:t.ONE_MINUS_DST_COLOR,[Im]:t.ONE_MINUS_DST_ALPHA,[Um]:t.CONSTANT_COLOR,[Om]:t.ONE_MINUS_CONSTANT_COLOR,[zm]:t.CONSTANT_ALPHA,[km]:t.ONE_MINUS_CONSTANT_ALPHA};function Je(L,ce,pe,_e,fe,ue,Ee,We,mt,nt){if(L===Tr){p===!0&&(Se(t.BLEND),p=!1);return}if(p===!1&&(ae(t.BLEND),p=!0),L!==wm){if(L!==g||nt!==S){if((m!==$r||_!==$r)&&(t.blendEquation(t.FUNC_ADD),m=$r,_=$r),nt)switch(L){case Ei:t.blendFuncSeparate(t.ONE,t.ONE_MINUS_SRC_ALPHA,t.ONE,t.ONE_MINUS_SRC_ALPHA);break;case sh:t.blendFunc(t.ONE,t.ONE);break;case ah:t.blendFuncSeparate(t.ZERO,t.ONE_MINUS_SRC_COLOR,t.ZERO,t.ONE);break;case uh:t.blendFuncSeparate(t.DST_COLOR,t.ONE_MINUS_SRC_ALPHA,t.ZERO,t.ONE);break;default:console.error("THREE.WebGLState: Invalid blending: ",L);break}else switch(L){case Ei:t.blendFuncSeparate(t.SRC_ALPHA,t.ONE_MINUS_SRC_ALPHA,t.ONE,t.ONE_MINUS_SRC_ALPHA);break;case sh:t.blendFuncSeparate(t.SRC_ALPHA,t.ONE,t.ONE,t.ONE);break;case ah:console.error("THREE.WebGLState: SubtractiveBlending requires material.premultipliedAlpha = true");break;case uh:console.error("THREE.WebGLState: MultiplyBlending requires material.premultipliedAlpha = true");break;default:console.error("THREE.WebGLState: Invalid blending: ",L);break}b=null,v=null,M=null,y=null,E.set(0,0,0),D=0,g=L,S=nt}return}fe=fe||ce,ue=ue||pe,Ee=Ee||_e,(ce!==m||fe!==_)&&(t.blendEquationSeparate(ut[ce],ut[fe]),m=ce,_=fe),(pe!==b||_e!==v||ue!==M||Ee!==y)&&(t.blendFuncSeparate(N[pe],N[_e],N[ue],N[Ee]),b=pe,v=_e,M=ue,y=Ee),(We.equals(E)===!1||mt!==D)&&(t.blendColor(We.r,We.g,We.b,mt),E.copy(We),D=mt),g=L,S=!1}function Ne(L,ce){L.side===fr?Se(t.CULL_FACE):ae(t.CULL_FACE);let pe=L.side===fn;ce&&(pe=!pe),Be(pe),L.blending===Ei&&L.transparent===!1?Je(Tr):Je(L.blending,L.blendEquation,L.blendSrc,L.blendDst,L.blendEquationAlpha,L.blendSrcAlpha,L.blendDstAlpha,L.blendColor,L.blendAlpha,L.premultipliedAlpha),s.setFunc(L.depthFunc),s.setTest(L.depthTest),s.setMask(L.depthWrite),o.setMask(L.colorWrite);let _e=L.stencilWrite;a.setTest(_e),_e&&(a.setMask(L.stencilWriteMask),a.setFunc(L.stencilFunc,L.stencilRef,L.stencilFuncMask),a.setOp(L.stencilFail,L.stencilZFail,L.stencilZPass)),Fe(L.polygonOffset,L.polygonOffsetFactor,L.polygonOffsetUnits),L.alphaToCoverage===!0?ae(t.SAMPLE_ALPHA_TO_COVERAGE):Se(t.SAMPLE_ALPHA_TO_COVERAGE)}function Be(L){w!==L&&(L?t.frontFace(t.CW):t.frontFace(t.CCW),w=L)}function Ae(L){L!==ym?(ae(t.CULL_FACE),L!==C&&(L===ih?t.cullFace(t.BACK):L===Mm?t.cullFace(t.FRONT):t.cullFace(t.FRONT_AND_BACK))):Se(t.CULL_FACE),C=L}function pt(L){L!==F&&(B&&t.lineWidth(L),F=L)}function Fe(L,ce,pe){L?(ae(t.POLYGON_OFFSET_FILL),(O!==ce||U!==pe)&&(t.polygonOffset(ce,pe),O=ce,U=pe)):Se(t.POLYGON_OFFSET_FILL)}function $e(L){L?ae(t.SCISSOR_TEST):Se(t.SCISSOR_TEST)}function It(L){L===void 0&&(L=t.TEXTURE0+z-1),ne!==L&&(t.activeTexture(L),ne=L)}function Et(L,ce,pe){pe===void 0&&(ne===null?pe=t.TEXTURE0+z-1:pe=ne);let _e=se[pe];_e===void 0&&(_e={type:void 0,texture:void 0},se[pe]=_e),(_e.type!==L||_e.texture!==ce)&&(ne!==pe&&(t.activeTexture(pe),ne=pe),t.bindTexture(L,ce||re[L]),_e.type=L,_e.texture=ce)}function P(){let L=se[ne];L!==void 0&&L.type!==void 0&&(t.bindTexture(L.type,null),L.type=void 0,L.texture=void 0)}function A(){try{t.compressedTexImage2D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function Z(){try{t.compressedTexImage3D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function le(){try{t.texSubImage2D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function de(){try{t.texSubImage3D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function oe(){try{t.compressedTexSubImage2D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function R(){try{t.compressedTexSubImage3D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function I(){try{t.texStorage2D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function V(){try{t.texStorage3D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function X(){try{t.texImage2D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function G(){try{t.texImage3D(...arguments)}catch(L){console.error("THREE.WebGLState:",L)}}function W(L){ze.equals(L)===!1&&(t.scissor(L.x,L.y,L.z,L.w),ze.copy(L))}function ie(L){Ze.equals(L)===!1&&(t.viewport(L.x,L.y,L.z,L.w),Ze.copy(L))}function $(L,ce){let pe=u.get(ce);pe===void 0&&(pe=new WeakMap,u.set(ce,pe));let _e=pe.get(L);_e===void 0&&(_e=t.getUniformBlockIndex(ce,L.name),pe.set(L,_e))}function ee(L,ce){let _e=u.get(ce).get(L);l.get(ce)!==_e&&(t.uniformBlockBinding(ce,_e,L.__bindingPointIndex),l.set(ce,_e))}function Q(){t.disable(t.BLEND),t.disable(t.CULL_FACE),t.disable(t.DEPTH_TEST),t.disable(t.POLYGON_OFFSET_FILL),t.disable(t.SCISSOR_TEST),t.disable(t.STENCIL_TEST),t.disable(t.SAMPLE_ALPHA_TO_COVERAGE),t.blendEquation(t.FUNC_ADD),t.blendFunc(t.ONE,t.ZERO),t.blendFuncSeparate(t.ONE,t.ZERO,t.ONE,t.ZERO),t.blendColor(0,0,0,0),t.colorMask(!0,!0,!0,!0),t.clearColor(0,0,0,0),t.depthMask(!0),t.depthFunc(t.LESS),s.setReversed(!1),t.clearDepth(1),t.stencilMask(4294967295),t.stencilFunc(t.ALWAYS,0,4294967295),t.stencilOp(t.KEEP,t.KEEP,t.KEEP),t.clearStencil(0),t.cullFace(t.BACK),t.frontFace(t.CCW),t.polygonOffset(0,0),t.activeTexture(t.TEXTURE0),t.bindFramebuffer(t.FRAMEBUFFER,null),t.bindFramebuffer(t.DRAW_FRAMEBUFFER,null),t.bindFramebuffer(t.READ_FRAMEBUFFER,null),t.useProgram(null),t.lineWidth(1),t.scissor(0,0,t.canvas.width,t.canvas.height),t.viewport(0,0,t.canvas.width,t.canvas.height),c={},ne=null,se={},f={},h=new WeakMap,d=[],x=null,p=!1,g=null,m=null,b=null,v=null,_=null,M=null,y=null,E=new it(0,0,0),D=0,S=!1,w=null,C=null,F=null,O=null,U=null,ze.set(0,0,t.canvas.width,t.canvas.height),Ze.set(0,0,t.canvas.width,t.canvas.height),o.reset(),s.reset(),a.reset()}return{buffers:{color:o,depth:s,stencil:a},enable:ae,disable:Se,bindFramebuffer:De,drawBuffers:xe,useProgram:Xe,setBlending:Je,setMaterial:Ne,setFlipSided:Be,setCullFace:Ae,setLineWidth:pt,setPolygonOffset:Fe,setScissorTest:$e,activeTexture:It,bindTexture:Et,unbindTexture:P,compressedTexImage2D:A,compressedTexImage3D:Z,texImage2D:X,texImage3D:G,updateUBOMapping:$,uniformBlockBinding:ee,texStorage2D:I,texStorage3D:V,texSubImage2D:le,texSubImage3D:de,compressedTexSubImage2D:oe,compressedTexSubImage3D:R,scissor:W,viewport:ie,reset:Q}}function zb(t,e,n,r,i,o,s){let a=e.has("WEBGL_multisampled_render_to_texture")?e.get("WEBGL_multisampled_render_to_texture"):null,l=typeof navigator>"u"?!1:/OculusBrowser/g.test(navigator.userAgent),u=new Ie,c=new WeakMap,f,h=new WeakMap,d=!1;try{d=typeof OffscreenCanvas<"u"&&new OffscreenCanvas(1,1).getContext("2d")!==null}catch{}function x(P,A){return d?new OffscreenCanvas(P,A):ws("canvas")}function p(P,A,Z){let le=1,de=Et(P);if((de.width>Z||de.height>Z)&&(le=Z/Math.max(de.width,de.height)),le<1)if(typeof HTMLImageElement<"u"&&P instanceof HTMLImageElement||typeof HTMLCanvasElement<"u"&&P instanceof HTMLCanvasElement||typeof ImageBitmap<"u"&&P instanceof ImageBitmap||typeof VideoFrame<"u"&&P instanceof VideoFrame){let oe=Math.floor(le*de.width),R=Math.floor(le*de.height);f===void 0&&(f=x(oe,R));let I=A?x(oe,R):f;return I.width=oe,I.height=R,I.getContext("2d").drawImage(P,0,0,oe,R),console.warn("THREE.WebGLRenderer: Texture has been resized from ("+de.width+"x"+de.height+") to ("+oe+"x"+R+")."),I}else return"data"in P&&console.warn("THREE.WebGLRenderer: Image in DataTexture is too big ("+de.width+"x"+de.height+")."),P;return P}function g(P){return P.generateMipmaps}function m(P){t.generateMipmap(P)}function b(P){return P.isWebGLCubeRenderTarget?t.TEXTURE_CUBE_MAP:P.isWebGL3DRenderTarget?t.TEXTURE_3D:P.isWebGLArrayRenderTarget||P.isCompressedArrayTexture?t.TEXTURE_2D_ARRAY:t.TEXTURE_2D}function v(P,A,Z,le,de=!1){if(P!==null){if(t[P]!==void 0)return t[P];console.warn("THREE.WebGLRenderer: Attempt to use non-existing WebGL internal format '"+P+"'")}let oe=A;if(A===t.RED&&(Z===t.FLOAT&&(oe=t.R32F),Z===t.HALF_FLOAT&&(oe=t.R16F),Z===t.UNSIGNED_BYTE&&(oe=t.R8)),A===t.RED_INTEGER&&(Z===t.UNSIGNED_BYTE&&(oe=t.R8UI),Z===t.UNSIGNED_SHORT&&(oe=t.R16UI),Z===t.UNSIGNED_INT&&(oe=t.R32UI),Z===t.BYTE&&(oe=t.R8I),Z===t.SHORT&&(oe=t.R16I),Z===t.INT&&(oe=t.R32I)),A===t.RG&&(Z===t.FLOAT&&(oe=t.RG32F),Z===t.HALF_FLOAT&&(oe=t.RG16F),Z===t.UNSIGNED_BYTE&&(oe=t.RG8)),A===t.RG_INTEGER&&(Z===t.UNSIGNED_BYTE&&(oe=t.RG8UI),Z===t.UNSIGNED_SHORT&&(oe=t.RG16UI),Z===t.UNSIGNED_INT&&(oe=t.RG32UI),Z===t.BYTE&&(oe=t.RG8I),Z===t.SHORT&&(oe=t.RG16I),Z===t.INT&&(oe=t.RG32I)),A===t.RGB_INTEGER&&(Z===t.UNSIGNED_BYTE&&(oe=t.RGB8UI),Z===t.UNSIGNED_SHORT&&(oe=t.RGB16UI),Z===t.UNSIGNED_INT&&(oe=t.RGB32UI),Z===t.BYTE&&(oe=t.RGB8I),Z===t.SHORT&&(oe=t.RGB16I),Z===t.INT&&(oe=t.RGB32I)),A===t.RGBA_INTEGER&&(Z===t.UNSIGNED_BYTE&&(oe=t.RGBA8UI),Z===t.UNSIGNED_SHORT&&(oe=t.RGBA16UI),Z===t.UNSIGNED_INT&&(oe=t.RGBA32UI),Z===t.BYTE&&(oe=t.RGBA8I),Z===t.SHORT&&(oe=t.RGBA16I),Z===t.INT&&(oe=t.RGBA32I)),A===t.RGB&&(Z===t.UNSIGNED_INT_5_9_9_9_REV&&(oe=t.RGB9_E5),Z===t.UNSIGNED_INT_10F_11F_11F_REV&&(oe=t.R11F_G11F_B10F)),A===t.RGBA){let R=de?Ms:ct.getTransfer(le);Z===t.FLOAT&&(oe=t.RGBA32F),Z===t.HALF_FLOAT&&(oe=t.RGBA16F),Z===t.UNSIGNED_BYTE&&(oe=R===gt?t.SRGB8_ALPHA8:t.RGBA8),Z===t.UNSIGNED_SHORT_4_4_4_4&&(oe=t.RGBA4),Z===t.UNSIGNED_SHORT_5_5_5_1&&(oe=t.RGB5_A1)}return(oe===t.R16F||oe===t.R32F||oe===t.RG16F||oe===t.RG32F||oe===t.RGBA16F||oe===t.RGBA32F)&&e.get("EXT_color_buffer_float"),oe}function _(P,A){let Z;return P?A===null||A===ni||A===Bo?Z=t.DEPTH24_STENCIL8:A===hr?Z=t.DEPTH32F_STENCIL8:A===No&&(Z=t.DEPTH24_STENCIL8,console.warn("DepthTexture: 16 bit depth attachment is not supported with stencil. Using 24-bit attachment.")):A===null||A===ni||A===Bo?Z=t.DEPTH_COMPONENT24:A===hr?Z=t.DEPTH_COMPONENT32F:A===No&&(Z=t.DEPTH_COMPONENT16),Z}function M(P,A){return g(P)===!0||P.isFramebufferTexture&&P.minFilter!==zn&&P.minFilter!==Jn?Math.log2(Math.max(A.width,A.height))+1:P.mipmaps!==void 0&&P.mipmaps.length>0?P.mipmaps.length:P.isCompressedTexture&&Array.isArray(P.image)?A.mipmaps.length:1}function y(P){let A=P.target;A.removeEventListener("dispose",y),D(A),A.isVideoTexture&&c.delete(A)}function E(P){let A=P.target;A.removeEventListener("dispose",E),w(A)}function D(P){let A=r.get(P);if(A.__webglInit===void 0)return;let Z=P.source,le=h.get(Z);if(le){let de=le[A.__cacheKey];de.usedTimes--,de.usedTimes===0&&S(P),Object.keys(le).length===0&&h.delete(Z)}r.remove(P)}function S(P){let A=r.get(P);t.deleteTexture(A.__webglTexture);let Z=P.source,le=h.get(Z);delete le[A.__cacheKey],s.memory.textures--}function w(P){let A=r.get(P);if(P.depthTexture&&(P.depthTexture.dispose(),r.remove(P.depthTexture)),P.isWebGLCubeRenderTarget)for(let le=0;le<6;le++){if(Array.isArray(A.__webglFramebuffer[le]))for(let de=0;de<A.__webglFramebuffer[le].length;de++)t.deleteFramebuffer(A.__webglFramebuffer[le][de]);else t.deleteFramebuffer(A.__webglFramebuffer[le]);A.__webglDepthbuffer&&t.deleteRenderbuffer(A.__webglDepthbuffer[le])}else{if(Array.isArray(A.__webglFramebuffer))for(let le=0;le<A.__webglFramebuffer.length;le++)t.deleteFramebuffer(A.__webglFramebuffer[le]);else t.deleteFramebuffer(A.__webglFramebuffer);if(A.__webglDepthbuffer&&t.deleteRenderbuffer(A.__webglDepthbuffer),A.__webglMultisampledFramebuffer&&t.deleteFramebuffer(A.__webglMultisampledFramebuffer),A.__webglColorRenderbuffer)for(let le=0;le<A.__webglColorRenderbuffer.length;le++)A.__webglColorRenderbuffer[le]&&t.deleteRenderbuffer(A.__webglColorRenderbuffer[le]);A.__webglDepthRenderbuffer&&t.deleteRenderbuffer(A.__webglDepthRenderbuffer)}let Z=P.textures;for(let le=0,de=Z.length;le<de;le++){let oe=r.get(Z[le]);oe.__webglTexture&&(t.deleteTexture(oe.__webglTexture),s.memory.textures--),r.remove(Z[le])}r.remove(P)}let C=0;function F(){C=0}function O(){let P=C;return P>=i.maxTextures&&console.warn("THREE.WebGLTextures: Trying to use "+P+" texture units while this GPU supports only "+i.maxTextures),C+=1,P}function U(P){let A=[];return A.push(P.wrapS),A.push(P.wrapT),A.push(P.wrapR||0),A.push(P.magFilter),A.push(P.minFilter),A.push(P.anisotropy),A.push(P.internalFormat),A.push(P.format),A.push(P.type),A.push(P.generateMipmaps),A.push(P.premultiplyAlpha),A.push(P.flipY),A.push(P.unpackAlignment),A.push(P.colorSpace),A.join()}function z(P,A){let Z=r.get(P);if(P.isVideoTexture&&$e(P),P.isRenderTargetTexture===!1&&P.isExternalTexture!==!0&&P.version>0&&Z.__version!==P.version){let le=P.image;if(le===null)console.warn("THREE.WebGLRenderer: Texture marked for update but no image data found.");else if(le.complete===!1)console.warn("THREE.WebGLRenderer: Texture marked for update but image is incomplete");else{re(Z,P,A);return}}else P.isExternalTexture&&(Z.__webglTexture=P.sourceTexture?P.sourceTexture:null);n.bindTexture(t.TEXTURE_2D,Z.__webglTexture,t.TEXTURE0+A)}function B(P,A){let Z=r.get(P);if(P.isRenderTargetTexture===!1&&P.version>0&&Z.__version!==P.version){re(Z,P,A);return}n.bindTexture(t.TEXTURE_2D_ARRAY,Z.__webglTexture,t.TEXTURE0+A)}function J(P,A){let Z=r.get(P);if(P.isRenderTargetTexture===!1&&P.version>0&&Z.__version!==P.version){re(Z,P,A);return}n.bindTexture(t.TEXTURE_3D,Z.__webglTexture,t.TEXTURE0+A)}function H(P,A){let Z=r.get(P);if(P.version>0&&Z.__version!==P.version){ae(Z,P,A);return}n.bindTexture(t.TEXTURE_CUBE_MAP,Z.__webglTexture,t.TEXTURE0+A)}let ne={[iu]:t.REPEAT,[Zr]:t.CLAMP_TO_EDGE,[ou]:t.MIRRORED_REPEAT},se={[zn]:t.NEAREST,[Jm]:t.NEAREST_MIPMAP_NEAREST,[Xs]:t.NEAREST_MIPMAP_LINEAR,[Jn]:t.LINEAR,[Wu]:t.LINEAR_MIPMAP_NEAREST,[ti]:t.LINEAR_MIPMAP_LINEAR},ge={[eg]:t.NEVER,[sg]:t.ALWAYS,[tg]:t.LESS,[yh]:t.LEQUAL,[ng]:t.EQUAL,[og]:t.GEQUAL,[rg]:t.GREATER,[ig]:t.NOTEQUAL};function Te(P,A){if(A.type===hr&&e.has("OES_texture_float_linear")===!1&&(A.magFilter===Jn||A.magFilter===Wu||A.magFilter===Xs||A.magFilter===ti||A.minFilter===Jn||A.minFilter===Wu||A.minFilter===Xs||A.minFilter===ti)&&console.warn("THREE.WebGLRenderer: Unable to use linear filtering with floating point textures. OES_texture_float_linear not supported on this device."),t.texParameteri(P,t.TEXTURE_WRAP_S,ne[A.wrapS]),t.texParameteri(P,t.TEXTURE_WRAP_T,ne[A.wrapT]),(P===t.TEXTURE_3D||P===t.TEXTURE_2D_ARRAY)&&t.texParameteri(P,t.TEXTURE_WRAP_R,ne[A.wrapR]),t.texParameteri(P,t.TEXTURE_MAG_FILTER,se[A.magFilter]),t.texParameteri(P,t.TEXTURE_MIN_FILTER,se[A.minFilter]),A.compareFunction&&(t.texParameteri(P,t.TEXTURE_COMPARE_MODE,t.COMPARE_REF_TO_TEXTURE),t.texParameteri(P,t.TEXTURE_COMPARE_FUNC,ge[A.compareFunction])),e.has("EXT_texture_filter_anisotropic")===!0){if(A.magFilter===zn||A.minFilter!==Xs&&A.minFilter!==ti||A.type===hr&&e.has("OES_texture_float_linear")===!1)return;if(A.anisotropy>1||r.get(A).__currentAnisotropy){let Z=e.get("EXT_texture_filter_anisotropic");t.texParameterf(P,Z.TEXTURE_MAX_ANISOTROPY_EXT,Math.min(A.anisotropy,i.getMaxAnisotropy())),r.get(A).__currentAnisotropy=A.anisotropy}}}function ze(P,A){let Z=!1;P.__webglInit===void 0&&(P.__webglInit=!0,A.addEventListener("dispose",y));let le=A.source,de=h.get(le);de===void 0&&(de={},h.set(le,de));let oe=U(A);if(oe!==P.__cacheKey){de[oe]===void 0&&(de[oe]={texture:t.createTexture(),usedTimes:0},s.memory.textures++,Z=!0),de[oe].usedTimes++;let R=de[P.__cacheKey];R!==void 0&&(de[P.__cacheKey].usedTimes--,R.usedTimes===0&&S(A)),P.__cacheKey=oe,P.__webglTexture=de[oe].texture}return Z}function Ze(P,A,Z){return Math.floor(Math.floor(P/Z)/A)}function ke(P,A,Z,le){let oe=P.updateRanges;if(oe.length===0)n.texSubImage2D(t.TEXTURE_2D,0,0,0,A.width,A.height,Z,le,A.data);else{oe.sort((G,W)=>G.start-W.start);let R=0;for(let G=1;G<oe.length;G++){let W=oe[R],ie=oe[G],$=W.start+W.count,ee=Ze(ie.start,A.width,4),Q=Ze(W.start,A.width,4);ie.start<=$+1&&ee===Q&&Ze(ie.start+ie.count-1,A.width,4)===ee?W.count=Math.max(W.count,ie.start+ie.count-W.start):(++R,oe[R]=ie)}oe.length=R+1;let I=t.getParameter(t.UNPACK_ROW_LENGTH),V=t.getParameter(t.UNPACK_SKIP_PIXELS),X=t.getParameter(t.UNPACK_SKIP_ROWS);t.pixelStorei(t.UNPACK_ROW_LENGTH,A.width);for(let G=0,W=oe.length;G<W;G++){let ie=oe[G],$=Math.floor(ie.start/4),ee=Math.ceil(ie.count/4),Q=$%A.width,L=Math.floor($/A.width),ce=ee,pe=1;t.pixelStorei(t.UNPACK_SKIP_PIXELS,Q),t.pixelStorei(t.UNPACK_SKIP_ROWS,L),n.texSubImage2D(t.TEXTURE_2D,0,Q,L,ce,pe,Z,le,A.data)}P.clearUpdateRanges(),t.pixelStorei(t.UNPACK_ROW_LENGTH,I),t.pixelStorei(t.UNPACK_SKIP_PIXELS,V),t.pixelStorei(t.UNPACK_SKIP_ROWS,X)}}function re(P,A,Z){let le=t.TEXTURE_2D;(A.isDataArrayTexture||A.isCompressedArrayTexture)&&(le=t.TEXTURE_2D_ARRAY),A.isData3DTexture&&(le=t.TEXTURE_3D);let de=ze(P,A),oe=A.source;n.bindTexture(le,P.__webglTexture,t.TEXTURE0+Z);let R=r.get(oe);if(oe.version!==R.__version||de===!0){n.activeTexture(t.TEXTURE0+Z);let I=ct.getPrimaries(ct.workingColorSpace),V=A.colorSpace===Fr?null:ct.getPrimaries(A.colorSpace),X=A.colorSpace===Fr||I===V?t.NONE:t.BROWSER_DEFAULT_WEBGL;t.pixelStorei(t.UNPACK_FLIP_Y_WEBGL,A.flipY),t.pixelStorei(t.UNPACK_PREMULTIPLY_ALPHA_WEBGL,A.premultiplyAlpha),t.pixelStorei(t.UNPACK_ALIGNMENT,A.unpackAlignment),t.pixelStorei(t.UNPACK_COLORSPACE_CONVERSION_WEBGL,X);let G=p(A.image,!1,i.maxTextureSize);G=It(A,G);let W=o.convert(A.format,A.colorSpace),ie=o.convert(A.type),$=v(A.internalFormat,W,ie,A.colorSpace,A.isVideoTexture);Te(le,A);let ee,Q=A.mipmaps,L=A.isVideoTexture!==!0,ce=R.__version===void 0||de===!0,pe=oe.dataReady,_e=M(A,G);if(A.isDepthTexture)$=_(A.format===Uo,A.type),ce&&(L?n.texStorage2D(t.TEXTURE_2D,1,$,G.width,G.height):n.texImage2D(t.TEXTURE_2D,0,$,G.width,G.height,0,W,ie,null));else if(A.isDataTexture)if(Q.length>0){L&&ce&&n.texStorage2D(t.TEXTURE_2D,_e,$,Q[0].width,Q[0].height);for(let fe=0,ue=Q.length;fe<ue;fe++)ee=Q[fe],L?pe&&n.texSubImage2D(t.TEXTURE_2D,fe,0,0,ee.width,ee.height,W,ie,ee.data):n.texImage2D(t.TEXTURE_2D,fe,$,ee.width,ee.height,0,W,ie,ee.data);A.generateMipmaps=!1}else L?(ce&&n.texStorage2D(t.TEXTURE_2D,_e,$,G.width,G.height),pe&&ke(A,G,W,ie)):n.texImage2D(t.TEXTURE_2D,0,$,G.width,G.height,0,W,ie,G.data);else if(A.isCompressedTexture)if(A.isCompressedArrayTexture){L&&ce&&n.texStorage3D(t.TEXTURE_2D_ARRAY,_e,$,Q[0].width,Q[0].height,G.depth);for(let fe=0,ue=Q.length;fe<ue;fe++)if(ee=Q[fe],A.format!==Hn)if(W!==null)if(L){if(pe)if(A.layerUpdates.size>0){let Ee=Th(ee.width,ee.height,A.format,A.type);for(let We of A.layerUpdates){let mt=ee.data.subarray(We*Ee/ee.data.BYTES_PER_ELEMENT,(We+1)*Ee/ee.data.BYTES_PER_ELEMENT);n.compressedTexSubImage3D(t.TEXTURE_2D_ARRAY,fe,0,0,We,ee.width,ee.height,1,W,mt)}A.clearLayerUpdates()}else n.compressedTexSubImage3D(t.TEXTURE_2D_ARRAY,fe,0,0,0,ee.width,ee.height,G.depth,W,ee.data)}else n.compressedTexImage3D(t.TEXTURE_2D_ARRAY,fe,$,ee.width,ee.height,G.depth,0,ee.data,0,0);else console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()");else L?pe&&n.texSubImage3D(t.TEXTURE_2D_ARRAY,fe,0,0,0,ee.width,ee.height,G.depth,W,ie,ee.data):n.texImage3D(t.TEXTURE_2D_ARRAY,fe,$,ee.width,ee.height,G.depth,0,W,ie,ee.data)}else{L&&ce&&n.texStorage2D(t.TEXTURE_2D,_e,$,Q[0].width,Q[0].height);for(let fe=0,ue=Q.length;fe<ue;fe++)ee=Q[fe],A.format!==Hn?W!==null?L?pe&&n.compressedTexSubImage2D(t.TEXTURE_2D,fe,0,0,ee.width,ee.height,W,ee.data):n.compressedTexImage2D(t.TEXTURE_2D,fe,$,ee.width,ee.height,0,ee.data):console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .uploadTexture()"):L?pe&&n.texSubImage2D(t.TEXTURE_2D,fe,0,0,ee.width,ee.height,W,ie,ee.data):n.texImage2D(t.TEXTURE_2D,fe,$,ee.width,ee.height,0,W,ie,ee.data)}else if(A.isDataArrayTexture)if(L){if(ce&&n.texStorage3D(t.TEXTURE_2D_ARRAY,_e,$,G.width,G.height,G.depth),pe)if(A.layerUpdates.size>0){let fe=Th(G.width,G.height,A.format,A.type);for(let ue of A.layerUpdates){let Ee=G.data.subarray(ue*fe/G.data.BYTES_PER_ELEMENT,(ue+1)*fe/G.data.BYTES_PER_ELEMENT);n.texSubImage3D(t.TEXTURE_2D_ARRAY,0,0,0,ue,G.width,G.height,1,W,ie,Ee)}A.clearLayerUpdates()}else n.texSubImage3D(t.TEXTURE_2D_ARRAY,0,0,0,0,G.width,G.height,G.depth,W,ie,G.data)}else n.texImage3D(t.TEXTURE_2D_ARRAY,0,$,G.width,G.height,G.depth,0,W,ie,G.data);else if(A.isData3DTexture)L?(ce&&n.texStorage3D(t.TEXTURE_3D,_e,$,G.width,G.height,G.depth),pe&&n.texSubImage3D(t.TEXTURE_3D,0,0,0,0,G.width,G.height,G.depth,W,ie,G.data)):n.texImage3D(t.TEXTURE_3D,0,$,G.width,G.height,G.depth,0,W,ie,G.data);else if(A.isFramebufferTexture){if(ce)if(L)n.texStorage2D(t.TEXTURE_2D,_e,$,G.width,G.height);else{let fe=G.width,ue=G.height;for(let Ee=0;Ee<_e;Ee++)n.texImage2D(t.TEXTURE_2D,Ee,$,fe,ue,0,W,ie,null),fe>>=1,ue>>=1}}else if(Q.length>0){if(L&&ce){let fe=Et(Q[0]);n.texStorage2D(t.TEXTURE_2D,_e,$,fe.width,fe.height)}for(let fe=0,ue=Q.length;fe<ue;fe++)ee=Q[fe],L?pe&&n.texSubImage2D(t.TEXTURE_2D,fe,0,0,W,ie,ee):n.texImage2D(t.TEXTURE_2D,fe,$,W,ie,ee);A.generateMipmaps=!1}else if(L){if(ce){let fe=Et(G);n.texStorage2D(t.TEXTURE_2D,_e,$,fe.width,fe.height)}pe&&n.texSubImage2D(t.TEXTURE_2D,0,0,0,W,ie,G)}else n.texImage2D(t.TEXTURE_2D,0,$,W,ie,G);g(A)&&m(le),R.__version=oe.version,A.onUpdate&&A.onUpdate(A)}P.__version=A.version}function ae(P,A,Z){if(A.image.length!==6)return;let le=ze(P,A),de=A.source;n.bindTexture(t.TEXTURE_CUBE_MAP,P.__webglTexture,t.TEXTURE0+Z);let oe=r.get(de);if(de.version!==oe.__version||le===!0){n.activeTexture(t.TEXTURE0+Z);let R=ct.getPrimaries(ct.workingColorSpace),I=A.colorSpace===Fr?null:ct.getPrimaries(A.colorSpace),V=A.colorSpace===Fr||R===I?t.NONE:t.BROWSER_DEFAULT_WEBGL;t.pixelStorei(t.UNPACK_FLIP_Y_WEBGL,A.flipY),t.pixelStorei(t.UNPACK_PREMULTIPLY_ALPHA_WEBGL,A.premultiplyAlpha),t.pixelStorei(t.UNPACK_ALIGNMENT,A.unpackAlignment),t.pixelStorei(t.UNPACK_COLORSPACE_CONVERSION_WEBGL,V);let X=A.isCompressedTexture||A.image[0].isCompressedTexture,G=A.image[0]&&A.image[0].isDataTexture,W=[];for(let ue=0;ue<6;ue++)!X&&!G?W[ue]=p(A.image[ue],!0,i.maxCubemapSize):W[ue]=G?A.image[ue].image:A.image[ue],W[ue]=It(A,W[ue]);let ie=W[0],$=o.convert(A.format,A.colorSpace),ee=o.convert(A.type),Q=v(A.internalFormat,$,ee,A.colorSpace),L=A.isVideoTexture!==!0,ce=oe.__version===void 0||le===!0,pe=de.dataReady,_e=M(A,ie);Te(t.TEXTURE_CUBE_MAP,A);let fe;if(X){L&&ce&&n.texStorage2D(t.TEXTURE_CUBE_MAP,_e,Q,ie.width,ie.height);for(let ue=0;ue<6;ue++){fe=W[ue].mipmaps;for(let Ee=0;Ee<fe.length;Ee++){let We=fe[Ee];A.format!==Hn?$!==null?L?pe&&n.compressedTexSubImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee,0,0,We.width,We.height,$,We.data):n.compressedTexImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee,Q,We.width,We.height,0,We.data):console.warn("THREE.WebGLRenderer: Attempt to load unsupported compressed texture format in .setTextureCube()"):L?pe&&n.texSubImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee,0,0,We.width,We.height,$,ee,We.data):n.texImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee,Q,We.width,We.height,0,$,ee,We.data)}}}else{if(fe=A.mipmaps,L&&ce){fe.length>0&&_e++;let ue=Et(W[0]);n.texStorage2D(t.TEXTURE_CUBE_MAP,_e,Q,ue.width,ue.height)}for(let ue=0;ue<6;ue++)if(G){L?pe&&n.texSubImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,0,0,W[ue].width,W[ue].height,$,ee,W[ue].data):n.texImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,Q,W[ue].width,W[ue].height,0,$,ee,W[ue].data);for(let Ee=0;Ee<fe.length;Ee++){let mt=fe[Ee].image[ue].image;L?pe&&n.texSubImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee+1,0,0,mt.width,mt.height,$,ee,mt.data):n.texImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee+1,Q,mt.width,mt.height,0,$,ee,mt.data)}}else{L?pe&&n.texSubImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,0,0,$,ee,W[ue]):n.texImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,0,Q,$,ee,W[ue]);for(let Ee=0;Ee<fe.length;Ee++){let We=fe[Ee];L?pe&&n.texSubImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee+1,0,0,$,ee,We.image[ue]):n.texImage2D(t.TEXTURE_CUBE_MAP_POSITIVE_X+ue,Ee+1,Q,$,ee,We.image[ue])}}}g(A)&&m(t.TEXTURE_CUBE_MAP),oe.__version=de.version,A.onUpdate&&A.onUpdate(A)}P.__version=A.version}function Se(P,A,Z,le,de,oe){let R=o.convert(Z.format,Z.colorSpace),I=o.convert(Z.type),V=v(Z.internalFormat,R,I,Z.colorSpace),X=r.get(A),G=r.get(Z);if(G.__renderTarget=A,!X.__hasExternalTextures){let W=Math.max(1,A.width>>oe),ie=Math.max(1,A.height>>oe);de===t.TEXTURE_3D||de===t.TEXTURE_2D_ARRAY?n.texImage3D(de,oe,V,W,ie,A.depth,0,R,I,null):n.texImage2D(de,oe,V,W,ie,0,R,I,null)}n.bindFramebuffer(t.FRAMEBUFFER,P),Fe(A)?a.framebufferTexture2DMultisampleEXT(t.FRAMEBUFFER,le,de,G.__webglTexture,0,pt(A)):(de===t.TEXTURE_2D||de>=t.TEXTURE_CUBE_MAP_POSITIVE_X&&de<=t.TEXTURE_CUBE_MAP_NEGATIVE_Z)&&t.framebufferTexture2D(t.FRAMEBUFFER,le,de,G.__webglTexture,oe),n.bindFramebuffer(t.FRAMEBUFFER,null)}function De(P,A,Z){if(t.bindRenderbuffer(t.RENDERBUFFER,P),A.depthBuffer){let le=A.depthTexture,de=le&&le.isDepthTexture?le.type:null,oe=_(A.stencilBuffer,de),R=A.stencilBuffer?t.DEPTH_STENCIL_ATTACHMENT:t.DEPTH_ATTACHMENT,I=pt(A);Fe(A)?a.renderbufferStorageMultisampleEXT(t.RENDERBUFFER,I,oe,A.width,A.height):Z?t.renderbufferStorageMultisample(t.RENDERBUFFER,I,oe,A.width,A.height):t.renderbufferStorage(t.RENDERBUFFER,oe,A.width,A.height),t.framebufferRenderbuffer(t.FRAMEBUFFER,R,t.RENDERBUFFER,P)}else{let le=A.textures;for(let de=0;de<le.length;de++){let oe=le[de],R=o.convert(oe.format,oe.colorSpace),I=o.convert(oe.type),V=v(oe.internalFormat,R,I,oe.colorSpace),X=pt(A);Z&&Fe(A)===!1?t.renderbufferStorageMultisample(t.RENDERBUFFER,X,V,A.width,A.height):Fe(A)?a.renderbufferStorageMultisampleEXT(t.RENDERBUFFER,X,V,A.width,A.height):t.renderbufferStorage(t.RENDERBUFFER,V,A.width,A.height)}}t.bindRenderbuffer(t.RENDERBUFFER,null)}function xe(P,A){if(A&&A.isWebGLCubeRenderTarget)throw new Error("Depth Texture with cube render targets is not supported");if(n.bindFramebuffer(t.FRAMEBUFFER,P),!(A.depthTexture&&A.depthTexture.isDepthTexture))throw new Error("renderTarget.depthTexture must be an instance of THREE.DepthTexture");let le=r.get(A.depthTexture);le.__renderTarget=A,(!le.__webglTexture||A.depthTexture.image.width!==A.width||A.depthTexture.image.height!==A.height)&&(A.depthTexture.image.width=A.width,A.depthTexture.image.height=A.height,A.depthTexture.needsUpdate=!0),z(A.depthTexture,0);let de=le.__webglTexture,oe=pt(A);if(A.depthTexture.format===wo)Fe(A)?a.framebufferTexture2DMultisampleEXT(t.FRAMEBUFFER,t.DEPTH_ATTACHMENT,t.TEXTURE_2D,de,0,oe):t.framebufferTexture2D(t.FRAMEBUFFER,t.DEPTH_ATTACHMENT,t.TEXTURE_2D,de,0);else if(A.depthTexture.format===Uo)Fe(A)?a.framebufferTexture2DMultisampleEXT(t.FRAMEBUFFER,t.DEPTH_STENCIL_ATTACHMENT,t.TEXTURE_2D,de,0,oe):t.framebufferTexture2D(t.FRAMEBUFFER,t.DEPTH_STENCIL_ATTACHMENT,t.TEXTURE_2D,de,0);else throw new Error("Unknown depthTexture format")}function Xe(P){let A=r.get(P),Z=P.isWebGLCubeRenderTarget===!0;if(A.__boundDepthTexture!==P.depthTexture){let le=P.depthTexture;if(A.__depthDisposeCallback&&A.__depthDisposeCallback(),le){let de=()=>{delete A.__boundDepthTexture,delete A.__depthDisposeCallback,le.removeEventListener("dispose",de)};le.addEventListener("dispose",de),A.__depthDisposeCallback=de}A.__boundDepthTexture=le}if(P.depthTexture&&!A.__autoAllocateDepthBuffer){if(Z)throw new Error("target.depthTexture not supported in Cube render targets");let le=P.texture.mipmaps;le&&le.length>0?xe(A.__webglFramebuffer[0],P):xe(A.__webglFramebuffer,P)}else if(Z){A.__webglDepthbuffer=[];for(let le=0;le<6;le++)if(n.bindFramebuffer(t.FRAMEBUFFER,A.__webglFramebuffer[le]),A.__webglDepthbuffer[le]===void 0)A.__webglDepthbuffer[le]=t.createRenderbuffer(),De(A.__webglDepthbuffer[le],P,!1);else{let de=P.stencilBuffer?t.DEPTH_STENCIL_ATTACHMENT:t.DEPTH_ATTACHMENT,oe=A.__webglDepthbuffer[le];t.bindRenderbuffer(t.RENDERBUFFER,oe),t.framebufferRenderbuffer(t.FRAMEBUFFER,de,t.RENDERBUFFER,oe)}}else{let le=P.texture.mipmaps;if(le&&le.length>0?n.bindFramebuffer(t.FRAMEBUFFER,A.__webglFramebuffer[0]):n.bindFramebuffer(t.FRAMEBUFFER,A.__webglFramebuffer),A.__webglDepthbuffer===void 0)A.__webglDepthbuffer=t.createRenderbuffer(),De(A.__webglDepthbuffer,P,!1);else{let de=P.stencilBuffer?t.DEPTH_STENCIL_ATTACHMENT:t.DEPTH_ATTACHMENT,oe=A.__webglDepthbuffer;t.bindRenderbuffer(t.RENDERBUFFER,oe),t.framebufferRenderbuffer(t.FRAMEBUFFER,de,t.RENDERBUFFER,oe)}}n.bindFramebuffer(t.FRAMEBUFFER,null)}function ut(P,A,Z){let le=r.get(P);A!==void 0&&Se(le.__webglFramebuffer,P,P.texture,t.COLOR_ATTACHMENT0,t.TEXTURE_2D,0),Z!==void 0&&Xe(P)}function N(P){let A=P.texture,Z=r.get(P),le=r.get(A);P.addEventListener("dispose",E);let de=P.textures,oe=P.isWebGLCubeRenderTarget===!0,R=de.length>1;if(R||(le.__webglTexture===void 0&&(le.__webglTexture=t.createTexture()),le.__version=A.version,s.memory.textures++),oe){Z.__webglFramebuffer=[];for(let I=0;I<6;I++)if(A.mipmaps&&A.mipmaps.length>0){Z.__webglFramebuffer[I]=[];for(let V=0;V<A.mipmaps.length;V++)Z.__webglFramebuffer[I][V]=t.createFramebuffer()}else Z.__webglFramebuffer[I]=t.createFramebuffer()}else{if(A.mipmaps&&A.mipmaps.length>0){Z.__webglFramebuffer=[];for(let I=0;I<A.mipmaps.length;I++)Z.__webglFramebuffer[I]=t.createFramebuffer()}else Z.__webglFramebuffer=t.createFramebuffer();if(R)for(let I=0,V=de.length;I<V;I++){let X=r.get(de[I]);X.__webglTexture===void 0&&(X.__webglTexture=t.createTexture(),s.memory.textures++)}if(P.samples>0&&Fe(P)===!1){Z.__webglMultisampledFramebuffer=t.createFramebuffer(),Z.__webglColorRenderbuffer=[],n.bindFramebuffer(t.FRAMEBUFFER,Z.__webglMultisampledFramebuffer);for(let I=0;I<de.length;I++){let V=de[I];Z.__webglColorRenderbuffer[I]=t.createRenderbuffer(),t.bindRenderbuffer(t.RENDERBUFFER,Z.__webglColorRenderbuffer[I]);let X=o.convert(V.format,V.colorSpace),G=o.convert(V.type),W=v(V.internalFormat,X,G,V.colorSpace,P.isXRRenderTarget===!0),ie=pt(P);t.renderbufferStorageMultisample(t.RENDERBUFFER,ie,W,P.width,P.height),t.framebufferRenderbuffer(t.FRAMEBUFFER,t.COLOR_ATTACHMENT0+I,t.RENDERBUFFER,Z.__webglColorRenderbuffer[I])}t.bindRenderbuffer(t.RENDERBUFFER,null),P.depthBuffer&&(Z.__webglDepthRenderbuffer=t.createRenderbuffer(),De(Z.__webglDepthRenderbuffer,P,!0)),n.bindFramebuffer(t.FRAMEBUFFER,null)}}if(oe){n.bindTexture(t.TEXTURE_CUBE_MAP,le.__webglTexture),Te(t.TEXTURE_CUBE_MAP,A);for(let I=0;I<6;I++)if(A.mipmaps&&A.mipmaps.length>0)for(let V=0;V<A.mipmaps.length;V++)Se(Z.__webglFramebuffer[I][V],P,A,t.COLOR_ATTACHMENT0,t.TEXTURE_CUBE_MAP_POSITIVE_X+I,V);else Se(Z.__webglFramebuffer[I],P,A,t.COLOR_ATTACHMENT0,t.TEXTURE_CUBE_MAP_POSITIVE_X+I,0);g(A)&&m(t.TEXTURE_CUBE_MAP),n.unbindTexture()}else if(R){for(let I=0,V=de.length;I<V;I++){let X=de[I],G=r.get(X),W=t.TEXTURE_2D;(P.isWebGL3DRenderTarget||P.isWebGLArrayRenderTarget)&&(W=P.isWebGL3DRenderTarget?t.TEXTURE_3D:t.TEXTURE_2D_ARRAY),n.bindTexture(W,G.__webglTexture),Te(W,X),Se(Z.__webglFramebuffer,P,X,t.COLOR_ATTACHMENT0+I,W,0),g(X)&&m(W)}n.unbindTexture()}else{let I=t.TEXTURE_2D;if((P.isWebGL3DRenderTarget||P.isWebGLArrayRenderTarget)&&(I=P.isWebGL3DRenderTarget?t.TEXTURE_3D:t.TEXTURE_2D_ARRAY),n.bindTexture(I,le.__webglTexture),Te(I,A),A.mipmaps&&A.mipmaps.length>0)for(let V=0;V<A.mipmaps.length;V++)Se(Z.__webglFramebuffer[V],P,A,t.COLOR_ATTACHMENT0,I,V);else Se(Z.__webglFramebuffer,P,A,t.COLOR_ATTACHMENT0,I,0);g(A)&&m(I),n.unbindTexture()}P.depthBuffer&&Xe(P)}function Je(P){let A=P.textures;for(let Z=0,le=A.length;Z<le;Z++){let de=A[Z];if(g(de)){let oe=b(P),R=r.get(de).__webglTexture;n.bindTexture(oe,R),m(oe),n.unbindTexture()}}}let Ne=[],Be=[];function Ae(P){if(P.samples>0){if(Fe(P)===!1){let A=P.textures,Z=P.width,le=P.height,de=t.COLOR_BUFFER_BIT,oe=P.stencilBuffer?t.DEPTH_STENCIL_ATTACHMENT:t.DEPTH_ATTACHMENT,R=r.get(P),I=A.length>1;if(I)for(let X=0;X<A.length;X++)n.bindFramebuffer(t.FRAMEBUFFER,R.__webglMultisampledFramebuffer),t.framebufferRenderbuffer(t.FRAMEBUFFER,t.COLOR_ATTACHMENT0+X,t.RENDERBUFFER,null),n.bindFramebuffer(t.FRAMEBUFFER,R.__webglFramebuffer),t.framebufferTexture2D(t.DRAW_FRAMEBUFFER,t.COLOR_ATTACHMENT0+X,t.TEXTURE_2D,null,0);n.bindFramebuffer(t.READ_FRAMEBUFFER,R.__webglMultisampledFramebuffer);let V=P.texture.mipmaps;V&&V.length>0?n.bindFramebuffer(t.DRAW_FRAMEBUFFER,R.__webglFramebuffer[0]):n.bindFramebuffer(t.DRAW_FRAMEBUFFER,R.__webglFramebuffer);for(let X=0;X<A.length;X++){if(P.resolveDepthBuffer&&(P.depthBuffer&&(de|=t.DEPTH_BUFFER_BIT),P.stencilBuffer&&P.resolveStencilBuffer&&(de|=t.STENCIL_BUFFER_BIT)),I){t.framebufferRenderbuffer(t.READ_FRAMEBUFFER,t.COLOR_ATTACHMENT0,t.RENDERBUFFER,R.__webglColorRenderbuffer[X]);let G=r.get(A[X]).__webglTexture;t.framebufferTexture2D(t.DRAW_FRAMEBUFFER,t.COLOR_ATTACHMENT0,t.TEXTURE_2D,G,0)}t.blitFramebuffer(0,0,Z,le,0,0,Z,le,de,t.NEAREST),l===!0&&(Ne.length=0,Be.length=0,Ne.push(t.COLOR_ATTACHMENT0+X),P.depthBuffer&&P.resolveDepthBuffer===!1&&(Ne.push(oe),Be.push(oe),t.invalidateFramebuffer(t.DRAW_FRAMEBUFFER,Be)),t.invalidateFramebuffer(t.READ_FRAMEBUFFER,Ne))}if(n.bindFramebuffer(t.READ_FRAMEBUFFER,null),n.bindFramebuffer(t.DRAW_FRAMEBUFFER,null),I)for(let X=0;X<A.length;X++){n.bindFramebuffer(t.FRAMEBUFFER,R.__webglMultisampledFramebuffer),t.framebufferRenderbuffer(t.FRAMEBUFFER,t.COLOR_ATTACHMENT0+X,t.RENDERBUFFER,R.__webglColorRenderbuffer[X]);let G=r.get(A[X]).__webglTexture;n.bindFramebuffer(t.FRAMEBUFFER,R.__webglFramebuffer),t.framebufferTexture2D(t.DRAW_FRAMEBUFFER,t.COLOR_ATTACHMENT0+X,t.TEXTURE_2D,G,0)}n.bindFramebuffer(t.DRAW_FRAMEBUFFER,R.__webglMultisampledFramebuffer)}else if(P.depthBuffer&&P.resolveDepthBuffer===!1&&l){let A=P.stencilBuffer?t.DEPTH_STENCIL_ATTACHMENT:t.DEPTH_ATTACHMENT;t.invalidateFramebuffer(t.DRAW_FRAMEBUFFER,[A])}}}function pt(P){return Math.min(i.maxSamples,P.samples)}function Fe(P){let A=r.get(P);return P.samples>0&&e.has("WEBGL_multisampled_render_to_texture")===!0&&A.__useRenderToTexture!==!1}function $e(P){let A=s.render.frame;c.get(P)!==A&&(c.set(P,A),P.update())}function It(P,A){let Z=P.colorSpace,le=P.format,de=P.type;return P.isCompressedTexture===!0||P.isVideoTexture===!0||Z!==Ai&&Z!==Fr&&(ct.getTransfer(Z)===gt?(le!==Hn||de!==er)&&console.warn("THREE.WebGLTextures: sRGB encoded textures have to use RGBAFormat and UnsignedByteType."):console.error("THREE.WebGLTextures: Unsupported texture color space:",Z)),A}function Et(P){return typeof HTMLImageElement<"u"&&P instanceof HTMLImageElement?(u.width=P.naturalWidth||P.width,u.height=P.naturalHeight||P.height):typeof VideoFrame<"u"&&P instanceof VideoFrame?(u.width=P.displayWidth,u.height=P.displayHeight):(u.width=P.width,u.height=P.height),u}this.allocateTextureUnit=O,this.resetTextureUnits=F,this.setTexture2D=z,this.setTexture2DArray=B,this.setTexture3D=J,this.setTextureCube=H,this.rebindTextures=ut,this.setupRenderTarget=N,this.updateRenderTargetMipmap=Je,this.updateMultisampleRenderTarget=Ae,this.setupDepthRenderbuffer=Xe,this.setupFrameBufferTexture=Se,this.useMultisampledRTT=Fe}function kb(t,e){function n(r,i=Fr){let o,s=ct.getTransfer(i);if(r===er)return t.UNSIGNED_BYTE;if(r===Xu)return t.UNSIGNED_SHORT_4_4_4_4;if(r===Yu)return t.UNSIGNED_SHORT_5_5_5_1;if(r===dh)return t.UNSIGNED_INT_5_9_9_9_REV;if(r===ph)return t.UNSIGNED_INT_10F_11F_11F_REV;if(r===fh)return t.BYTE;if(r===hh)return t.SHORT;if(r===No)return t.UNSIGNED_SHORT;if(r===qu)return t.INT;if(r===ni)return t.UNSIGNED_INT;if(r===hr)return t.FLOAT;if(r===Lo)return t.HALF_FLOAT;if(r===mh)return t.ALPHA;if(r===gh)return t.RGB;if(r===Hn)return t.RGBA;if(r===wo)return t.DEPTH_COMPONENT;if(r===Uo)return t.DEPTH_STENCIL;if(r===xh)return t.RED;if(r===Zu)return t.RED_INTEGER;if(r===vh)return t.RG;if(r===$u)return t.RG_INTEGER;if(r===Ju)return t.RGBA_INTEGER;if(r===Ys||r===Zs||r===$s||r===Js)if(s===gt)if(o=e.get("WEBGL_compressed_texture_s3tc_srgb"),o!==null){if(r===Ys)return o.COMPRESSED_SRGB_S3TC_DXT1_EXT;if(r===Zs)return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT1_EXT;if(r===$s)return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT3_EXT;if(r===Js)return o.COMPRESSED_SRGB_ALPHA_S3TC_DXT5_EXT}else return null;else if(o=e.get("WEBGL_compressed_texture_s3tc"),o!==null){if(r===Ys)return o.COMPRESSED_RGB_S3TC_DXT1_EXT;if(r===Zs)return o.COMPRESSED_RGBA_S3TC_DXT1_EXT;if(r===$s)return o.COMPRESSED_RGBA_S3TC_DXT3_EXT;if(r===Js)return o.COMPRESSED_RGBA_S3TC_DXT5_EXT}else return null;if(r===Ku||r===Qu||r===ju||r===el)if(o=e.get("WEBGL_compressed_texture_pvrtc"),o!==null){if(r===Ku)return o.COMPRESSED_RGB_PVRTC_4BPPV1_IMG;if(r===Qu)return o.COMPRESSED_RGB_PVRTC_2BPPV1_IMG;if(r===ju)return o.COMPRESSED_RGBA_PVRTC_4BPPV1_IMG;if(r===el)return o.COMPRESSED_RGBA_PVRTC_2BPPV1_IMG}else return null;if(r===tl||r===nl||r===rl)if(o=e.get("WEBGL_compressed_texture_etc"),o!==null){if(r===tl||r===nl)return s===gt?o.COMPRESSED_SRGB8_ETC2:o.COMPRESSED_RGB8_ETC2;if(r===rl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ETC2_EAC:o.COMPRESSED_RGBA8_ETC2_EAC}else return null;if(r===il||r===ol||r===sl||r===al||r===ul||r===ll||r===cl||r===fl||r===hl||r===dl||r===pl||r===ml||r===gl||r===xl)if(o=e.get("WEBGL_compressed_texture_astc"),o!==null){if(r===il)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR:o.COMPRESSED_RGBA_ASTC_4x4_KHR;if(r===ol)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR:o.COMPRESSED_RGBA_ASTC_5x4_KHR;if(r===sl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR:o.COMPRESSED_RGBA_ASTC_5x5_KHR;if(r===al)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR:o.COMPRESSED_RGBA_ASTC_6x5_KHR;if(r===ul)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR:o.COMPRESSED_RGBA_ASTC_6x6_KHR;if(r===ll)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR:o.COMPRESSED_RGBA_ASTC_8x5_KHR;if(r===cl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR:o.COMPRESSED_RGBA_ASTC_8x6_KHR;if(r===fl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR:o.COMPRESSED_RGBA_ASTC_8x8_KHR;if(r===hl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR:o.COMPRESSED_RGBA_ASTC_10x5_KHR;if(r===dl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR:o.COMPRESSED_RGBA_ASTC_10x6_KHR;if(r===pl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR:o.COMPRESSED_RGBA_ASTC_10x8_KHR;if(r===ml)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR:o.COMPRESSED_RGBA_ASTC_10x10_KHR;if(r===gl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR:o.COMPRESSED_RGBA_ASTC_12x10_KHR;if(r===xl)return s===gt?o.COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR:o.COMPRESSED_RGBA_ASTC_12x12_KHR}else return null;if(r===vl||r===_l||r===yl)if(o=e.get("EXT_texture_compression_bptc"),o!==null){if(r===vl)return s===gt?o.COMPRESSED_SRGB_ALPHA_BPTC_UNORM_EXT:o.COMPRESSED_RGBA_BPTC_UNORM_EXT;if(r===_l)return o.COMPRESSED_RGB_BPTC_SIGNED_FLOAT_EXT;if(r===yl)return o.COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_EXT}else return null;if(r===Ml||r===Sl||r===wl||r===bl)if(o=e.get("EXT_texture_compression_rgtc"),o!==null){if(r===Ml)return o.COMPRESSED_RED_RGTC1_EXT;if(r===Sl)return o.COMPRESSED_SIGNED_RED_RGTC1_EXT;if(r===wl)return o.COMPRESSED_RED_GREEN_RGTC2_EXT;if(r===bl)return o.COMPRESSED_SIGNED_RED_GREEN_RGTC2_EXT}else return null;return r===Bo?t.UNSIGNED_INT_24_8:t[r]!==void 0?t[r]:null}return{convert:n}}var Vb=`
void main() {

	gl_Position = vec4( position, 1.0 );

}`,Hb=`
uniform sampler2DArray depthColor;
uniform float depthWidth;
uniform float depthHeight;

void main() {

	vec2 coord = vec2( gl_FragCoord.x / depthWidth, gl_FragCoord.y / depthHeight );

	if ( coord.x >= 1.0 ) {

		gl_FragDepth = texture( depthColor, vec3( coord.x - 1.0, coord.y, 1 ) ).r;

	} else {

		gl_FragDepth = texture( depthColor, vec3( coord.x, coord.y, 0 ) ).r;

	}

}`,Hh=class{constructor(){this.texture=null,this.mesh=null,this.depthNear=0,this.depthFar=0}init(e,n){if(this.texture===null){let r=new Ps(e.texture);(e.depthNear!==n.depthNear||e.depthFar!==n.depthFar)&&(this.depthNear=e.depthNear,this.depthFar=e.depthFar),this.texture=r}}getMesh(e){if(this.texture!==null&&this.mesh===null){let n=e.cameras[0].viewport,r=new jn({vertexShader:Vb,fragmentShader:Hb,uniforms:{depthColor:{value:this.texture},depthWidth:{value:n.z},depthHeight:{value:n.w}}});this.mesh=new Lt(new Ri(20,20),r)}return this.mesh}reset(){this.texture=null,this.mesh=null}getDepthTexture(){return this.texture}},Gh=class extends ur{constructor(e,n){super();let r=this,i=null,o=1,s=null,a="local-floor",l=1,u=null,c=null,f=null,h=null,d=null,x=null,p=typeof XRWebGLBinding<"u",g=new Hh,m={},b=n.getContextAttributes(),v=null,_=null,M=[],y=[],E=new Ie,D=null,S=new tn;S.viewport=new Ft;let w=new tn;w.viewport=new Ft;let C=[S,w],F=new Nu,O=null,U=null;this.cameraAutoUpdate=!0,this.enabled=!1,this.isPresenting=!1,this.getController=function(re){let ae=M[re];return ae===void 0&&(ae=new Co,M[re]=ae),ae.getTargetRaySpace()},this.getControllerGrip=function(re){let ae=M[re];return ae===void 0&&(ae=new Co,M[re]=ae),ae.getGripSpace()},this.getHand=function(re){let ae=M[re];return ae===void 0&&(ae=new Co,M[re]=ae),ae.getHandSpace()};function z(re){let ae=y.indexOf(re.inputSource);if(ae===-1)return;let Se=M[ae];Se!==void 0&&(Se.update(re.inputSource,re.frame,u||s),Se.dispatchEvent({type:re.type,data:re.inputSource}))}function B(){i.removeEventListener("select",z),i.removeEventListener("selectstart",z),i.removeEventListener("selectend",z),i.removeEventListener("squeeze",z),i.removeEventListener("squeezestart",z),i.removeEventListener("squeezeend",z),i.removeEventListener("end",B),i.removeEventListener("inputsourceschange",J);for(let re=0;re<M.length;re++){let ae=y[re];ae!==null&&(y[re]=null,M[re].disconnect(ae))}O=null,U=null,g.reset();for(let re in m)delete m[re];e.setRenderTarget(v),d=null,h=null,f=null,i=null,_=null,ke.stop(),r.isPresenting=!1,e.setPixelRatio(D),e.setSize(E.width,E.height,!1),r.dispatchEvent({type:"sessionend"})}this.setFramebufferScaleFactor=function(re){o=re,r.isPresenting===!0&&console.warn("THREE.WebXRManager: Cannot change framebuffer scale while presenting.")},this.setReferenceSpaceType=function(re){a=re,r.isPresenting===!0&&console.warn("THREE.WebXRManager: Cannot change reference space type while presenting.")},this.getReferenceSpace=function(){return u||s},this.setReferenceSpace=function(re){u=re},this.getBaseLayer=function(){return h!==null?h:d},this.getBinding=function(){return f===null&&p&&(f=new XRWebGLBinding(i,n)),f},this.getFrame=function(){return x},this.getSession=function(){return i},this.setSession=async function(re){if(i=re,i!==null){if(v=e.getRenderTarget(),i.addEventListener("select",z),i.addEventListener("selectstart",z),i.addEventListener("selectend",z),i.addEventListener("squeeze",z),i.addEventListener("squeezestart",z),i.addEventListener("squeezeend",z),i.addEventListener("end",B),i.addEventListener("inputsourceschange",J),b.xrCompatible!==!0&&await n.makeXRCompatible(),D=e.getPixelRatio(),e.getSize(E),p&&"createProjectionLayer"in XRWebGLBinding.prototype){let Se=null,De=null,xe=null;b.depth&&(xe=b.stencil?n.DEPTH24_STENCIL8:n.DEPTH_COMPONENT24,Se=b.stencil?Uo:wo,De=b.stencil?Bo:ni);let Xe={colorFormat:n.RGBA8,depthFormat:xe,scaleFactor:o};f=this.getBinding(),h=f.createProjectionLayer(Xe),i.updateRenderState({layers:[h]}),e.setPixelRatio(1),e.setSize(h.textureWidth,h.textureHeight,!1),_=new lr(h.textureWidth,h.textureHeight,{format:Hn,type:er,depthTexture:new Fs(h.textureWidth,h.textureHeight,De,void 0,void 0,void 0,void 0,void 0,void 0,Se),stencilBuffer:b.stencil,colorSpace:e.outputColorSpace,samples:b.antialias?4:0,resolveDepthBuffer:h.ignoreDepthValues===!1,resolveStencilBuffer:h.ignoreDepthValues===!1})}else{let Se={antialias:b.antialias,alpha:!0,depth:b.depth,stencil:b.stencil,framebufferScaleFactor:o};d=new XRWebGLLayer(i,n,Se),i.updateRenderState({baseLayer:d}),e.setPixelRatio(1),e.setSize(d.framebufferWidth,d.framebufferHeight,!1),_=new lr(d.framebufferWidth,d.framebufferHeight,{format:Hn,type:er,colorSpace:e.outputColorSpace,stencilBuffer:b.stencil,resolveDepthBuffer:d.ignoreDepthValues===!1,resolveStencilBuffer:d.ignoreDepthValues===!1})}_.isXRRenderTarget=!0,this.setFoveation(l),u=null,s=await i.requestReferenceSpace(a),ke.setContext(i),ke.start(),r.isPresenting=!0,r.dispatchEvent({type:"sessionstart"})}},this.getEnvironmentBlendMode=function(){if(i!==null)return i.environmentBlendMode},this.getDepthTexture=function(){return g.getDepthTexture()};function J(re){for(let ae=0;ae<re.removed.length;ae++){let Se=re.removed[ae],De=y.indexOf(Se);De>=0&&(y[De]=null,M[De].disconnect(Se))}for(let ae=0;ae<re.added.length;ae++){let Se=re.added[ae],De=y.indexOf(Se);if(De===-1){for(let Xe=0;Xe<M.length;Xe++)if(Xe>=y.length){y.push(Se),De=Xe;break}else if(y[Xe]===null){y[Xe]=Se,De=Xe;break}if(De===-1)break}let xe=M[De];xe&&xe.connect(Se)}}let H=new k,ne=new k;function se(re,ae,Se){H.setFromMatrixPosition(ae.matrixWorld),ne.setFromMatrixPosition(Se.matrixWorld);let De=H.distanceTo(ne),xe=ae.projectionMatrix.elements,Xe=Se.projectionMatrix.elements,ut=xe[14]/(xe[10]-1),N=xe[14]/(xe[10]+1),Je=(xe[9]+1)/xe[5],Ne=(xe[9]-1)/xe[5],Be=(xe[8]-1)/xe[0],Ae=(Xe[8]+1)/Xe[0],pt=ut*Be,Fe=ut*Ae,$e=De/(-Be+Ae),It=$e*-Be;if(ae.matrixWorld.decompose(re.position,re.quaternion,re.scale),re.translateX(It),re.translateZ($e),re.matrixWorld.compose(re.position,re.quaternion,re.scale),re.matrixWorldInverse.copy(re.matrixWorld).invert(),xe[10]===-1)re.projectionMatrix.copy(ae.projectionMatrix),re.projectionMatrixInverse.copy(ae.projectionMatrixInverse);else{let Et=ut+$e,P=N+$e,A=pt-It,Z=Fe+(De-It),le=Je*N/P*Et,de=Ne*N/P*Et;re.projectionMatrix.makePerspective(A,Z,le,de,Et,P),re.projectionMatrixInverse.copy(re.projectionMatrix).invert()}}function ge(re,ae){ae===null?re.matrixWorld.copy(re.matrix):re.matrixWorld.multiplyMatrices(ae.matrixWorld,re.matrix),re.matrixWorldInverse.copy(re.matrixWorld).invert()}this.updateCamera=function(re){if(i===null)return;let ae=re.near,Se=re.far;g.texture!==null&&(g.depthNear>0&&(ae=g.depthNear),g.depthFar>0&&(Se=g.depthFar)),F.near=w.near=S.near=ae,F.far=w.far=S.far=Se,(O!==F.near||U!==F.far)&&(i.updateRenderState({depthNear:F.near,depthFar:F.far}),O=F.near,U=F.far),F.layers.mask=re.layers.mask|6,S.layers.mask=F.layers.mask&3,w.layers.mask=F.layers.mask&5;let De=re.parent,xe=F.cameras;ge(F,De);for(let Xe=0;Xe<xe.length;Xe++)ge(xe[Xe],De);xe.length===2?se(F,S,w):F.projectionMatrix.copy(S.projectionMatrix),Te(re,F,De)};function Te(re,ae,Se){Se===null?re.matrix.copy(ae.matrixWorld):(re.matrix.copy(Se.matrixWorld),re.matrix.invert(),re.matrix.multiply(ae.matrixWorld)),re.matrix.decompose(re.position,re.quaternion,re.scale),re.updateMatrixWorld(!0),re.projectionMatrix.copy(ae.projectionMatrix),re.projectionMatrixInverse.copy(ae.projectionMatrixInverse),re.isPerspectiveCamera&&(re.fov=bo*2*Math.atan(1/re.projectionMatrix.elements[5]),re.zoom=1)}this.getCamera=function(){return F},this.getFoveation=function(){if(!(h===null&&d===null))return l},this.setFoveation=function(re){l=re,h!==null&&(h.fixedFoveation=re),d!==null&&d.fixedFoveation!==void 0&&(d.fixedFoveation=re)},this.hasDepthSensing=function(){return g.texture!==null},this.getDepthSensingMesh=function(){return g.getMesh(F)},this.getCameraTexture=function(re){return m[re]};let ze=null;function Ze(re,ae){if(c=ae.getViewerPose(u||s),x=ae,c!==null){let Se=c.views;d!==null&&(e.setRenderTargetFramebuffer(_,d.framebuffer),e.setRenderTarget(_));let De=!1;Se.length!==F.cameras.length&&(F.cameras.length=0,De=!0);for(let N=0;N<Se.length;N++){let Je=Se[N],Ne=null;if(d!==null)Ne=d.getViewport(Je);else{let Ae=f.getViewSubImage(h,Je);Ne=Ae.viewport,N===0&&(e.setRenderTargetTextures(_,Ae.colorTexture,Ae.depthStencilTexture),e.setRenderTarget(_))}let Be=C[N];Be===void 0&&(Be=new tn,Be.layers.enable(N),Be.viewport=new Ft,C[N]=Be),Be.matrix.fromArray(Je.transform.matrix),Be.matrix.decompose(Be.position,Be.quaternion,Be.scale),Be.projectionMatrix.fromArray(Je.projectionMatrix),Be.projectionMatrixInverse.copy(Be.projectionMatrix).invert(),Be.viewport.set(Ne.x,Ne.y,Ne.width,Ne.height),N===0&&(F.matrix.copy(Be.matrix),F.matrix.decompose(F.position,F.quaternion,F.scale)),De===!0&&F.cameras.push(Be)}let xe=i.enabledFeatures;if(xe&&xe.includes("depth-sensing")&&i.depthUsage=="gpu-optimized"&&p){f=r.getBinding();let N=f.getDepthInformation(Se[0]);N&&N.isValid&&N.texture&&g.init(N,i.renderState)}if(xe&&xe.includes("camera-access")&&p){e.state.unbindTexture(),f=r.getBinding();for(let N=0;N<Se.length;N++){let Je=Se[N].camera;if(Je){let Ne=m[Je];Ne||(Ne=new Ps,m[Je]=Ne);let Be=f.getCameraImage(Je);Ne.sourceTexture=Be}}}}for(let Se=0;Se<M.length;Se++){let De=y[Se],xe=M[Se];De!==null&&xe!==void 0&&xe.update(De,ae,u||s)}ze&&ze(re,ae),ae.detectedPlanes&&r.dispatchEvent({type:"planesdetected",data:ae}),x=null}let ke=new Lg;ke.setAnimationLoop(Ze),this.setAnimationLoop=function(re){ze=re},this.dispose=function(){}}},Bi=new Kn,Gb=new Rt;function Wb(t,e){function n(g,m){g.matrixAutoUpdate===!0&&g.updateMatrix(),m.value.copy(g.matrix)}function r(g,m){m.color.getRGB(g.fogColor.value,Eh(t)),m.isFog?(g.fogNear.value=m.near,g.fogFar.value=m.far):m.isFogExp2&&(g.fogDensity.value=m.density)}function i(g,m,b,v,_){m.isMeshBasicMaterial||m.isMeshLambertMaterial?o(g,m):m.isMeshToonMaterial?(o(g,m),f(g,m)):m.isMeshPhongMaterial?(o(g,m),c(g,m)):m.isMeshStandardMaterial?(o(g,m),h(g,m),m.isMeshPhysicalMaterial&&d(g,m,_)):m.isMeshMatcapMaterial?(o(g,m),x(g,m)):m.isMeshDepthMaterial?o(g,m):m.isMeshDistanceMaterial?(o(g,m),p(g,m)):m.isMeshNormalMaterial?o(g,m):m.isLineBasicMaterial?(s(g,m),m.isLineDashedMaterial&&a(g,m)):m.isPointsMaterial?l(g,m,b,v):m.isSpriteMaterial?u(g,m):m.isShadowMaterial?(g.color.value.copy(m.color),g.opacity.value=m.opacity):m.isShaderMaterial&&(m.uniformsNeedUpdate=!1)}function o(g,m){g.opacity.value=m.opacity,m.color&&g.diffuse.value.copy(m.color),m.emissive&&g.emissive.value.copy(m.emissive).multiplyScalar(m.emissiveIntensity),m.map&&(g.map.value=m.map,n(m.map,g.mapTransform)),m.alphaMap&&(g.alphaMap.value=m.alphaMap,n(m.alphaMap,g.alphaMapTransform)),m.bumpMap&&(g.bumpMap.value=m.bumpMap,n(m.bumpMap,g.bumpMapTransform),g.bumpScale.value=m.bumpScale,m.side===fn&&(g.bumpScale.value*=-1)),m.normalMap&&(g.normalMap.value=m.normalMap,n(m.normalMap,g.normalMapTransform),g.normalScale.value.copy(m.normalScale),m.side===fn&&g.normalScale.value.negate()),m.displacementMap&&(g.displacementMap.value=m.displacementMap,n(m.displacementMap,g.displacementMapTransform),g.displacementScale.value=m.displacementScale,g.displacementBias.value=m.displacementBias),m.emissiveMap&&(g.emissiveMap.value=m.emissiveMap,n(m.emissiveMap,g.emissiveMapTransform)),m.specularMap&&(g.specularMap.value=m.specularMap,n(m.specularMap,g.specularMapTransform)),m.alphaTest>0&&(g.alphaTest.value=m.alphaTest);let b=e.get(m),v=b.envMap,_=b.envMapRotation;v&&(g.envMap.value=v,Bi.copy(_),Bi.x*=-1,Bi.y*=-1,Bi.z*=-1,v.isCubeTexture&&v.isRenderTargetTexture===!1&&(Bi.y*=-1,Bi.z*=-1),g.envMapRotation.value.setFromMatrix4(Gb.makeRotationFromEuler(Bi)),g.flipEnvMap.value=v.isCubeTexture&&v.isRenderTargetTexture===!1?-1:1,g.reflectivity.value=m.reflectivity,g.ior.value=m.ior,g.refractionRatio.value=m.refractionRatio),m.lightMap&&(g.lightMap.value=m.lightMap,g.lightMapIntensity.value=m.lightMapIntensity,n(m.lightMap,g.lightMapTransform)),m.aoMap&&(g.aoMap.value=m.aoMap,g.aoMapIntensity.value=m.aoMapIntensity,n(m.aoMap,g.aoMapTransform))}function s(g,m){g.diffuse.value.copy(m.color),g.opacity.value=m.opacity,m.map&&(g.map.value=m.map,n(m.map,g.mapTransform))}function a(g,m){g.dashSize.value=m.dashSize,g.totalSize.value=m.dashSize+m.gapSize,g.scale.value=m.scale}function l(g,m,b,v){g.diffuse.value.copy(m.color),g.opacity.value=m.opacity,g.size.value=m.size*b,g.scale.value=v*.5,m.map&&(g.map.value=m.map,n(m.map,g.uvTransform)),m.alphaMap&&(g.alphaMap.value=m.alphaMap,n(m.alphaMap,g.alphaMapTransform)),m.alphaTest>0&&(g.alphaTest.value=m.alphaTest)}function u(g,m){g.diffuse.value.copy(m.color),g.opacity.value=m.opacity,g.rotation.value=m.rotation,m.map&&(g.map.value=m.map,n(m.map,g.mapTransform)),m.alphaMap&&(g.alphaMap.value=m.alphaMap,n(m.alphaMap,g.alphaMapTransform)),m.alphaTest>0&&(g.alphaTest.value=m.alphaTest)}function c(g,m){g.specular.value.copy(m.specular),g.shininess.value=Math.max(m.shininess,1e-4)}function f(g,m){m.gradientMap&&(g.gradientMap.value=m.gradientMap)}function h(g,m){g.metalness.value=m.metalness,m.metalnessMap&&(g.metalnessMap.value=m.metalnessMap,n(m.metalnessMap,g.metalnessMapTransform)),g.roughness.value=m.roughness,m.roughnessMap&&(g.roughnessMap.value=m.roughnessMap,n(m.roughnessMap,g.roughnessMapTransform)),m.envMap&&(g.envMapIntensity.value=m.envMapIntensity)}function d(g,m,b){g.ior.value=m.ior,m.sheen>0&&(g.sheenColor.value.copy(m.sheenColor).multiplyScalar(m.sheen),g.sheenRoughness.value=m.sheenRoughness,m.sheenColorMap&&(g.sheenColorMap.value=m.sheenColorMap,n(m.sheenColorMap,g.sheenColorMapTransform)),m.sheenRoughnessMap&&(g.sheenRoughnessMap.value=m.sheenRoughnessMap,n(m.sheenRoughnessMap,g.sheenRoughnessMapTransform))),m.clearcoat>0&&(g.clearcoat.value=m.clearcoat,g.clearcoatRoughness.value=m.clearcoatRoughness,m.clearcoatMap&&(g.clearcoatMap.value=m.clearcoatMap,n(m.clearcoatMap,g.clearcoatMapTransform)),m.clearcoatRoughnessMap&&(g.clearcoatRoughnessMap.value=m.clearcoatRoughnessMap,n(m.clearcoatRoughnessMap,g.clearcoatRoughnessMapTransform)),m.clearcoatNormalMap&&(g.clearcoatNormalMap.value=m.clearcoatNormalMap,n(m.clearcoatNormalMap,g.clearcoatNormalMapTransform),g.clearcoatNormalScale.value.copy(m.clearcoatNormalScale),m.side===fn&&g.clearcoatNormalScale.value.negate())),m.dispersion>0&&(g.dispersion.value=m.dispersion),m.iridescence>0&&(g.iridescence.value=m.iridescence,g.iridescenceIOR.value=m.iridescenceIOR,g.iridescenceThicknessMinimum.value=m.iridescenceThicknessRange[0],g.iridescenceThicknessMaximum.value=m.iridescenceThicknessRange[1],m.iridescenceMap&&(g.iridescenceMap.value=m.iridescenceMap,n(m.iridescenceMap,g.iridescenceMapTransform)),m.iridescenceThicknessMap&&(g.iridescenceThicknessMap.value=m.iridescenceThicknessMap,n(m.iridescenceThicknessMap,g.iridescenceThicknessMapTransform))),m.transmission>0&&(g.transmission.value=m.transmission,g.transmissionSamplerMap.value=b.texture,g.transmissionSamplerSize.value.set(b.width,b.height),m.transmissionMap&&(g.transmissionMap.value=m.transmissionMap,n(m.transmissionMap,g.transmissionMapTransform)),g.thickness.value=m.thickness,m.thicknessMap&&(g.thicknessMap.value=m.thicknessMap,n(m.thicknessMap,g.thicknessMapTransform)),g.attenuationDistance.value=m.attenuationDistance,g.attenuationColor.value.copy(m.attenuationColor)),m.anisotropy>0&&(g.anisotropyVector.value.set(m.anisotropy*Math.cos(m.anisotropyRotation),m.anisotropy*Math.sin(m.anisotropyRotation)),m.anisotropyMap&&(g.anisotropyMap.value=m.anisotropyMap,n(m.anisotropyMap,g.anisotropyMapTransform))),g.specularIntensity.value=m.specularIntensity,g.specularColor.value.copy(m.specularColor),m.specularColorMap&&(g.specularColorMap.value=m.specularColorMap,n(m.specularColorMap,g.specularColorMapTransform)),m.specularIntensityMap&&(g.specularIntensityMap.value=m.specularIntensityMap,n(m.specularIntensityMap,g.specularIntensityMapTransform))}function x(g,m){m.matcap&&(g.matcap.value=m.matcap)}function p(g,m){let b=e.get(m).light;g.referencePosition.value.setFromMatrixPosition(b.matrixWorld),g.nearDistance.value=b.shadow.camera.near,g.farDistance.value=b.shadow.camera.far}return{refreshFogUniforms:r,refreshMaterialUniforms:i}}function qb(t,e,n,r){let i={},o={},s=[],a=t.getParameter(t.MAX_UNIFORM_BUFFER_BINDINGS);function l(b,v){let _=v.program;r.uniformBlockBinding(b,_)}function u(b,v){let _=i[b.id];_===void 0&&(x(b),_=c(b),i[b.id]=_,b.addEventListener("dispose",g));let M=v.program;r.updateUBOMapping(b,M);let y=e.render.frame;o[b.id]!==y&&(h(b),o[b.id]=y)}function c(b){let v=f();b.__bindingPointIndex=v;let _=t.createBuffer(),M=b.__size,y=b.usage;return t.bindBuffer(t.UNIFORM_BUFFER,_),t.bufferData(t.UNIFORM_BUFFER,M,y),t.bindBuffer(t.UNIFORM_BUFFER,null),t.bindBufferBase(t.UNIFORM_BUFFER,v,_),_}function f(){for(let b=0;b<a;b++)if(s.indexOf(b)===-1)return s.push(b),b;return console.error("THREE.WebGLRenderer: Maximum number of simultaneously usable uniforms groups reached."),0}function h(b){let v=i[b.id],_=b.uniforms,M=b.__cache;t.bindBuffer(t.UNIFORM_BUFFER,v);for(let y=0,E=_.length;y<E;y++){let D=Array.isArray(_[y])?_[y]:[_[y]];for(let S=0,w=D.length;S<w;S++){let C=D[S];if(d(C,y,S,M)===!0){let F=C.__offset,O=Array.isArray(C.value)?C.value:[C.value],U=0;for(let z=0;z<O.length;z++){let B=O[z],J=p(B);typeof B=="number"||typeof B=="boolean"?(C.__data[0]=B,t.bufferSubData(t.UNIFORM_BUFFER,F+U,C.__data)):B.isMatrix3?(C.__data[0]=B.elements[0],C.__data[1]=B.elements[1],C.__data[2]=B.elements[2],C.__data[3]=0,C.__data[4]=B.elements[3],C.__data[5]=B.elements[4],C.__data[6]=B.elements[5],C.__data[7]=0,C.__data[8]=B.elements[6],C.__data[9]=B.elements[7],C.__data[10]=B.elements[8],C.__data[11]=0):(B.toArray(C.__data,U),U+=J.storage/Float32Array.BYTES_PER_ELEMENT)}t.bufferSubData(t.UNIFORM_BUFFER,F,C.__data)}}}t.bindBuffer(t.UNIFORM_BUFFER,null)}function d(b,v,_,M){let y=b.value,E=v+"_"+_;if(M[E]===void 0)return typeof y=="number"||typeof y=="boolean"?M[E]=y:M[E]=y.clone(),!0;{let D=M[E];if(typeof y=="number"||typeof y=="boolean"){if(D!==y)return M[E]=y,!0}else if(D.equals(y)===!1)return D.copy(y),!0}return!1}function x(b){let v=b.uniforms,_=0,M=16;for(let E=0,D=v.length;E<D;E++){let S=Array.isArray(v[E])?v[E]:[v[E]];for(let w=0,C=S.length;w<C;w++){let F=S[w],O=Array.isArray(F.value)?F.value:[F.value];for(let U=0,z=O.length;U<z;U++){let B=O[U],J=p(B),H=_%M,ne=H%J.boundary,se=H+ne;_+=ne,se!==0&&M-se<J.storage&&(_+=M-se),F.__data=new Float32Array(J.storage/Float32Array.BYTES_PER_ELEMENT),F.__offset=_,_+=J.storage}}}let y=_%M;return y>0&&(_+=M-y),b.__size=_,b.__cache={},this}function p(b){let v={boundary:0,storage:0};return typeof b=="number"||typeof b=="boolean"?(v.boundary=4,v.storage=4):b.isVector2?(v.boundary=8,v.storage=8):b.isVector3||b.isColor?(v.boundary=16,v.storage=12):b.isVector4?(v.boundary=16,v.storage=16):b.isMatrix3?(v.boundary=48,v.storage=48):b.isMatrix4?(v.boundary=64,v.storage=64):b.isTexture?console.warn("THREE.WebGLRenderer: Texture samplers can not be part of an uniforms group."):console.warn("THREE.WebGLRenderer: Unsupported uniform value type.",b),v}function g(b){let v=b.target;v.removeEventListener("dispose",g);let _=s.indexOf(v.__bindingPointIndex);s.splice(_,1),t.deleteBuffer(i[v.id]),delete i[v.id],delete o[v.id]}function m(){for(let b in i)t.deleteBuffer(i[b]);s=[],i={},o={}}return{bind:l,update:u,dispose:m}}var Tl=class{constructor(e={}){let{canvas:n=ag(),context:r=null,depth:i=!0,stencil:o=!1,alpha:s=!1,antialias:a=!1,premultipliedAlpha:l=!0,preserveDrawingBuffer:u=!1,powerPreference:c="default",failIfMajorPerformanceCaveat:f=!1,reversedDepthBuffer:h=!1}=e;this.isWebGLRenderer=!0;let d;if(r!==null){if(typeof WebGLRenderingContext<"u"&&r instanceof WebGLRenderingContext)throw new Error("THREE.WebGLRenderer: WebGL 1 is not supported since r163.");d=r.getContextAttributes().alpha}else d=s;let x=new Uint32Array(4),p=new Int32Array(4),g=null,m=null,b=[],v=[];this.domElement=n,this.debug={checkShaderErrors:!0,onShaderError:null},this.autoClear=!0,this.autoClearColor=!0,this.autoClearDepth=!0,this.autoClearStencil=!0,this.sortObjects=!0,this.clippingPlanes=[],this.localClippingEnabled=!1,this.toneMapping=Rr,this.toneMappingExposure=1,this.transmissionResolutionScale=1;let _=this,M=!1;this._outputColorSpace=An;let y=0,E=0,D=null,S=-1,w=null,C=new Ft,F=new Ft,O=null,U=new it(0),z=0,B=n.width,J=n.height,H=1,ne=null,se=null,ge=new Ft(0,0,B,J),Te=new Ft(0,0,B,J),ze=!1,Ze=new To,ke=!1,re=!1,ae=new Rt,Se=new k,De=new Ft,xe={background:null,fog:null,environment:null,overrideMaterial:null,isScene:!0},Xe=!1;function ut(){return D===null?H:1}let N=r;function Je(T,q){return n.getContext(T,q)}try{let T={alpha:!0,depth:i,stencil:o,antialias:a,premultipliedAlpha:l,preserveDrawingBuffer:u,powerPreference:c,failIfMajorPerformanceCaveat:f};if("setAttribute"in n&&n.setAttribute("data-engine",`three.js r${"180"}`),n.addEventListener("webglcontextlost",pe,!1),n.addEventListener("webglcontextrestored",_e,!1),n.addEventListener("webglcontextcreationerror",fe,!1),N===null){let q="webgl2";if(N=Je(q,T),N===null)throw Je(q)?new Error("Error creating WebGL context with your selected attributes."):new Error("Error creating WebGL context.")}}catch(T){throw console.error("THREE.WebGLRenderer: "+T.message),T}let Ne,Be,Ae,pt,Fe,$e,It,Et,P,A,Z,le,de,oe,R,I,V,X,G,W,ie,$,ee,Q;function L(){Ne=new lw(N),Ne.init(),$=new kb(N,Ne),Be=new nw(N,Ne,e,$),Ae=new Ob(N,Ne),Be.reversedDepthBuffer&&h&&Ae.buffers.depth.setReversed(!0),pt=new hw(N),Fe=new Eb,$e=new zb(N,Ne,Ae,Fe,Be,$,pt),It=new iw(_),Et=new uw(_),P=new v1(N),ee=new ew(N,P),A=new cw(N,P,pt,ee),Z=new pw(N,A,P,pt),G=new dw(N,Be,$e),I=new rw(Fe),le=new bb(_,It,Et,Ne,Be,ee,I),de=new Wb(_,Fe),oe=new Ab,R=new Ib(Ne),X=new jS(_,It,Et,Ae,Z,d,l),V=new Bb(_,Z,Be),Q=new qb(N,pt,Be,Ae),W=new tw(N,Ne,pt),ie=new fw(N,Ne,pt),pt.programs=le.programs,_.capabilities=Be,_.extensions=Ne,_.properties=Fe,_.renderLists=oe,_.shadowMap=V,_.state=Ae,_.info=pt}L();let ce=new Gh(_,N);this.xr=ce,this.getContext=function(){return N},this.getContextAttributes=function(){return N.getContextAttributes()},this.forceContextLoss=function(){let T=Ne.get("WEBGL_lose_context");T&&T.loseContext()},this.forceContextRestore=function(){let T=Ne.get("WEBGL_lose_context");T&&T.restoreContext()},this.getPixelRatio=function(){return H},this.setPixelRatio=function(T){T!==void 0&&(H=T,this.setSize(B,J,!1))},this.getSize=function(T){return T.set(B,J)},this.setSize=function(T,q,j=!0){if(ce.isPresenting){console.warn("THREE.WebGLRenderer: Can't change size while VR device is presenting.");return}B=T,J=q,n.width=Math.floor(T*H),n.height=Math.floor(q*H),j===!0&&(n.style.width=T+"px",n.style.height=q+"px"),this.setViewport(0,0,T,q)},this.getDrawingBufferSize=function(T){return T.set(B*H,J*H).floor()},this.setDrawingBufferSize=function(T,q,j){B=T,J=q,H=j,n.width=Math.floor(T*j),n.height=Math.floor(q*j),this.setViewport(0,0,T,q)},this.getCurrentViewport=function(T){return T.copy(C)},this.getViewport=function(T){return T.copy(ge)},this.setViewport=function(T,q,j,te){T.isVector4?ge.set(T.x,T.y,T.z,T.w):ge.set(T,q,j,te),Ae.viewport(C.copy(ge).multiplyScalar(H).round())},this.getScissor=function(T){return T.copy(Te)},this.setScissor=function(T,q,j,te){T.isVector4?Te.set(T.x,T.y,T.z,T.w):Te.set(T,q,j,te),Ae.scissor(F.copy(Te).multiplyScalar(H).round())},this.getScissorTest=function(){return ze},this.setScissorTest=function(T){Ae.setScissorTest(ze=T)},this.setOpaqueSort=function(T){ne=T},this.setTransparentSort=function(T){se=T},this.getClearColor=function(T){return T.copy(X.getClearColor())},this.setClearColor=function(){X.setClearColor(...arguments)},this.getClearAlpha=function(){return X.getClearAlpha()},this.setClearAlpha=function(){X.setClearAlpha(...arguments)},this.clear=function(T=!0,q=!0,j=!0){let te=0;if(T){let Y=!1;if(D!==null){let me=D.texture.format;Y=me===Ju||me===$u||me===Zu}if(Y){let me=D.texture.type,be=me===er||me===ni||me===No||me===Bo||me===Xu||me===Yu,Pe=X.getClearColor(),Re=X.getClearAlpha(),Oe=Pe.r,ye=Pe.g,Ce=Pe.b;be?(x[0]=Oe,x[1]=ye,x[2]=Ce,x[3]=Re,N.clearBufferuiv(N.COLOR,0,x)):(p[0]=Oe,p[1]=ye,p[2]=Ce,p[3]=Re,N.clearBufferiv(N.COLOR,0,p))}else te|=N.COLOR_BUFFER_BIT}q&&(te|=N.DEPTH_BUFFER_BIT),j&&(te|=N.STENCIL_BUFFER_BIT,this.state.buffers.stencil.setMask(4294967295)),N.clear(te)},this.clearColor=function(){this.clear(!0,!1,!1)},this.clearDepth=function(){this.clear(!1,!0,!1)},this.clearStencil=function(){this.clear(!1,!1,!0)},this.dispose=function(){n.removeEventListener("webglcontextlost",pe,!1),n.removeEventListener("webglcontextrestored",_e,!1),n.removeEventListener("webglcontextcreationerror",fe,!1),X.dispose(),oe.dispose(),R.dispose(),Fe.dispose(),It.dispose(),Et.dispose(),Z.dispose(),ee.dispose(),Q.dispose(),le.dispose(),ce.dispose(),ce.removeEventListener("sessionstart",Nn),ce.removeEventListener("sessionend",Da),_r.stop()};function pe(T){T.preventDefault(),console.log("THREE.WebGLRenderer: Context Lost."),M=!0}function _e(){console.log("THREE.WebGLRenderer: Context Restored."),M=!1;let T=pt.autoReset,q=V.enabled,j=V.autoUpdate,te=V.needsUpdate,Y=V.type;L(),pt.autoReset=T,V.enabled=q,V.autoUpdate=j,V.needsUpdate=te,V.type=Y}function fe(T){console.error("THREE.WebGLRenderer: A WebGL context could not be created. Reason: ",T.statusMessage)}function ue(T){let q=T.target;q.removeEventListener("dispose",ue),Ee(q)}function Ee(T){We(T),Fe.remove(T)}function We(T){let q=Fe.get(T).programs;q!==void 0&&(q.forEach(function(j){le.releaseProgram(j)}),T.isShaderMaterial&&le.releaseShaderCache(T))}this.renderBufferDirect=function(T,q,j,te,Y,me){q===null&&(q=xe);let be=Y.isMesh&&Y.matrixWorld.determinant()<0,Pe=gf(T,q,j,te,Y);Ae.setMaterial(te,be);let Re=j.index,Oe=1;if(te.wireframe===!0){if(Re=A.getWireframeAttribute(j),Re===void 0)return;Oe=2}let ye=j.drawRange,Ce=j.attributes.position,tt=ye.start*Oe,lt=(ye.start+ye.count)*Oe;me!==null&&(tt=Math.max(tt,me.start*Oe),lt=Math.min(lt,(me.start+me.count)*Oe)),Re!==null?(tt=Math.max(tt,0),lt=Math.min(lt,Re.count)):Ce!=null&&(tt=Math.max(tt,0),lt=Math.min(lt,Ce.count));let xt=lt-tt;if(xt<0||xt===1/0)return;ee.setup(Y,te,Pe,j,Re);let _t,yt=W;if(Re!==null&&(_t=P.get(Re),yt=ie,yt.setIndex(_t)),Y.isMesh)te.wireframe===!0?(Ae.setLineWidth(te.wireframeLinewidth*ut()),yt.setMode(N.LINES)):yt.setMode(N.TRIANGLES);else if(Y.isLine){let He=te.linewidth;He===void 0&&(He=1),Ae.setLineWidth(He*ut()),Y.isLineSegments?yt.setMode(N.LINES):Y.isLineLoop?yt.setMode(N.LINE_LOOP):yt.setMode(N.LINE_STRIP)}else Y.isPoints?yt.setMode(N.POINTS):Y.isSprite&&yt.setMode(N.TRIANGLES);if(Y.isBatchedMesh)if(Y._multiDrawInstances!==null)Eo("THREE.WebGLRenderer: renderMultiDrawInstances has been deprecated and will be removed in r184. Append to renderMultiDraw arguments and use indirection."),yt.renderMultiDrawInstances(Y._multiDrawStarts,Y._multiDrawCounts,Y._multiDrawCount,Y._multiDrawInstances);else if(Ne.get("WEBGL_multi_draw"))yt.renderMultiDraw(Y._multiDrawStarts,Y._multiDrawCounts,Y._multiDrawCount);else{let He=Y._multiDrawStarts,Ct=Y._multiDrawCounts,dt=Y._multiDrawCount,wn=Re?P.get(Re).bytesPerElement:1,ao=Fe.get(te).currentProgram.getUniforms();for(let bn=0;bn<dt;bn++)ao.setValue(N,"_gl_DrawID",bn),yt.render(He[bn]/wn,Ct[bn])}else if(Y.isInstancedMesh)yt.renderInstances(tt,xt,Y.count);else if(j.isInstancedBufferGeometry){let He=j._maxInstanceCount!==void 0?j._maxInstanceCount:1/0,Ct=Math.min(j.instanceCount,He);yt.renderInstances(tt,xt,Ct)}else yt.render(tt,xt)};function mt(T,q,j){T.transparent===!0&&T.side===fr&&T.forceSinglePass===!1?(T.side=fn,T.needsUpdate=!0,so(T,q,j),T.side=Ar,T.needsUpdate=!0,so(T,q,j),T.side=fr):so(T,q,j)}this.compile=function(T,q,j=null){j===null&&(j=T),m=R.get(j),m.init(q),v.push(m),j.traverseVisible(function(Y){Y.isLight&&Y.layers.test(q.layers)&&(m.pushLight(Y),Y.castShadow&&m.pushShadow(Y))}),T!==j&&T.traverseVisible(function(Y){Y.isLight&&Y.layers.test(q.layers)&&(m.pushLight(Y),Y.castShadow&&m.pushShadow(Y))}),m.setupLights();let te=new Set;return T.traverse(function(Y){if(!(Y.isMesh||Y.isPoints||Y.isLine||Y.isSprite))return;let me=Y.material;if(me)if(Array.isArray(me))for(let be=0;be<me.length;be++){let Pe=me[be];mt(Pe,j,Y),te.add(Pe)}else mt(me,j,Y),te.add(me)}),m=v.pop(),te},this.compileAsync=function(T,q,j=null){let te=this.compile(T,q,j);return new Promise(Y=>{function me(){if(te.forEach(function(be){Fe.get(be).currentProgram.isReady()&&te.delete(be)}),te.size===0){Y(T);return}setTimeout(me,10)}Ne.get("KHR_parallel_shader_compile")!==null?me():setTimeout(me,10)})};let nt=null;function pn(T){nt&&nt(T)}function Nn(){_r.stop()}function Da(){_r.start()}let _r=new Lg;_r.setAnimationLoop(pn),typeof self<"u"&&_r.setContext(self),this.setAnimationLoop=function(T){nt=T,ce.setAnimationLoop(T),T===null?_r.stop():_r.start()},ce.addEventListener("sessionstart",Nn),ce.addEventListener("sessionend",Da),this.render=function(T,q){if(q!==void 0&&q.isCamera!==!0){console.error("THREE.WebGLRenderer.render: camera is not an instance of THREE.Camera.");return}if(M===!0)return;if(T.matrixWorldAutoUpdate===!0&&T.updateMatrixWorld(),q.parent===null&&q.matrixWorldAutoUpdate===!0&&q.updateMatrixWorld(),ce.enabled===!0&&ce.isPresenting===!0&&(ce.cameraAutoUpdate===!0&&ce.updateCamera(q),q=ce.getCamera()),T.isScene===!0&&T.onBeforeRender(_,T,q,D),m=R.get(T,v.length),m.init(q),v.push(m),ae.multiplyMatrices(q.projectionMatrix,q.matrixWorldInverse),Ze.setFromProjectionMatrix(ae,$n,q.reversedDepth),re=this.localClippingEnabled,ke=I.init(this.clippingPlanes,re),g=oe.get(T,b.length),g.init(),b.push(g),ce.enabled===!0&&ce.isPresenting===!0){let me=_.xr.getDepthSensingMesh();me!==null&&ls(me,q,-1/0,_.sortObjects)}ls(T,q,0,_.sortObjects),g.finish(),_.sortObjects===!0&&g.sort(ne,se),Xe=ce.enabled===!1||ce.isPresenting===!1||ce.hasDepthSensing()===!1,Xe&&X.addToRenderList(g,T),this.info.render.frame++,ke===!0&&I.beginShadows();let j=m.state.shadowsArray;V.render(j,T,q),ke===!0&&I.endShadows(),this.info.autoReset===!0&&this.info.reset();let te=g.opaque,Y=g.transmissive;if(m.setupLights(),q.isArrayCamera){let me=q.cameras;if(Y.length>0)for(let be=0,Pe=me.length;be<Pe;be++){let Re=me[be];Ca(te,Y,T,Re)}Xe&&X.render(T);for(let be=0,Pe=me.length;be<Pe;be++){let Re=me[be];Aa(g,T,Re,Re.viewport)}}else Y.length>0&&Ca(te,Y,T,q),Xe&&X.render(T),Aa(g,T,q);D!==null&&E===0&&($e.updateMultisampleRenderTarget(D),$e.updateRenderTargetMipmap(D)),T.isScene===!0&&T.onAfterRender(_,T,q),ee.resetDefaultState(),S=-1,w=null,v.pop(),v.length>0?(m=v[v.length-1],ke===!0&&I.setGlobalState(_.clippingPlanes,m.state.camera)):m=null,b.pop(),b.length>0?g=b[b.length-1]:g=null};function ls(T,q,j,te){if(T.visible===!1)return;if(T.layers.test(q.layers)){if(T.isGroup)j=T.renderOrder;else if(T.isLOD)T.autoUpdate===!0&&T.update(q);else if(T.isLight)m.pushLight(T),T.castShadow&&m.pushShadow(T);else if(T.isSprite){if(!T.frustumCulled||Ze.intersectsSprite(T)){te&&De.setFromMatrixPosition(T.matrixWorld).applyMatrix4(ae);let be=Z.update(T),Pe=T.material;Pe.visible&&g.push(T,be,Pe,j,De.z,null)}}else if((T.isMesh||T.isLine||T.isPoints)&&(!T.frustumCulled||Ze.intersectsObject(T))){let be=Z.update(T),Pe=T.material;if(te&&(T.boundingSphere!==void 0?(T.boundingSphere===null&&T.computeBoundingSphere(),De.copy(T.boundingSphere.center)):(be.boundingSphere===null&&be.computeBoundingSphere(),De.copy(be.boundingSphere.center)),De.applyMatrix4(T.matrixWorld).applyMatrix4(ae)),Array.isArray(Pe)){let Re=be.groups;for(let Oe=0,ye=Re.length;Oe<ye;Oe++){let Ce=Re[Oe],tt=Pe[Ce.materialIndex];tt&&tt.visible&&g.push(T,be,tt,j,De.z,Ce)}}else Pe.visible&&g.push(T,be,Pe,j,De.z,null)}}let me=T.children;for(let be=0,Pe=me.length;be<Pe;be++)ls(me[be],q,j,te)}function Aa(T,q,j,te){let Y=T.opaque,me=T.transmissive,be=T.transparent;m.setupLightsView(j),ke===!0&&I.setGlobalState(_.clippingPlanes,j),te&&Ae.viewport(C.copy(te)),Y.length>0&&oo(Y,q,j),me.length>0&&oo(me,q,j),be.length>0&&oo(be,q,j),Ae.buffers.depth.setTest(!0),Ae.buffers.depth.setMask(!0),Ae.buffers.color.setMask(!0),Ae.setPolygonOffset(!1)}function Ca(T,q,j,te){if((j.isScene===!0?j.overrideMaterial:null)!==null)return;m.state.transmissionRenderTarget[te.id]===void 0&&(m.state.transmissionRenderTarget[te.id]=new lr(1,1,{generateMipmaps:!0,type:Ne.has("EXT_color_buffer_half_float")||Ne.has("EXT_color_buffer_float")?Lo:er,minFilter:ti,samples:4,stencilBuffer:o,resolveDepthBuffer:!1,resolveStencilBuffer:!1,colorSpace:ct.workingColorSpace}));let me=m.state.transmissionRenderTarget[te.id],be=te.viewport||C;me.setSize(be.z*_.transmissionResolutionScale,be.w*_.transmissionResolutionScale);let Pe=_.getRenderTarget(),Re=_.getActiveCubeFace(),Oe=_.getActiveMipmapLevel();_.setRenderTarget(me),_.getClearColor(U),z=_.getClearAlpha(),z<1&&_.setClearColor(16777215,.5),_.clear(),Xe&&X.render(j);let ye=_.toneMapping;_.toneMapping=Rr;let Ce=te.viewport;if(te.viewport!==void 0&&(te.viewport=void 0),m.setupLightsView(te),ke===!0&&I.setGlobalState(_.clippingPlanes,te),oo(T,j,te),$e.updateMultisampleRenderTarget(me),$e.updateRenderTargetMipmap(me),Ne.has("WEBGL_multisampled_render_to_texture")===!1){let tt=!1;for(let lt=0,xt=q.length;lt<xt;lt++){let _t=q[lt],yt=_t.object,He=_t.geometry,Ct=_t.material,dt=_t.group;if(Ct.side===fr&&yt.layers.test(te.layers)){let wn=Ct.side;Ct.side=fn,Ct.needsUpdate=!0,Ta(yt,j,te,He,Ct,dt),Ct.side=wn,Ct.needsUpdate=!0,tt=!0}}tt===!0&&($e.updateMultisampleRenderTarget(me),$e.updateRenderTargetMipmap(me))}_.setRenderTarget(Pe,Re,Oe),_.setClearColor(U,z),Ce!==void 0&&(te.viewport=Ce),_.toneMapping=ye}function oo(T,q,j){let te=q.isScene===!0?q.overrideMaterial:null;for(let Y=0,me=T.length;Y<me;Y++){let be=T[Y],Pe=be.object,Re=be.geometry,Oe=be.group,ye=be.material;ye.allowOverride===!0&&te!==null&&(ye=te),Pe.layers.test(j.layers)&&Ta(Pe,q,j,Re,ye,Oe)}}function Ta(T,q,j,te,Y,me){T.onBeforeRender(_,q,j,te,Y,me),T.modelViewMatrix.multiplyMatrices(j.matrixWorldInverse,T.matrixWorld),T.normalMatrix.getNormalMatrix(T.modelViewMatrix),Y.onBeforeRender(_,q,j,te,T,me),Y.transparent===!0&&Y.side===fr&&Y.forceSinglePass===!1?(Y.side=fn,Y.needsUpdate=!0,_.renderBufferDirect(j,q,te,Y,T,me),Y.side=Ar,Y.needsUpdate=!0,_.renderBufferDirect(j,q,te,Y,T,me),Y.side=fr):_.renderBufferDirect(j,q,te,Y,T,me),T.onAfterRender(_,q,j,te,Y,me)}function so(T,q,j){q.isScene!==!0&&(q=xe);let te=Fe.get(T),Y=m.state.lights,me=m.state.shadowsArray,be=Y.state.version,Pe=le.getParameters(T,Y.state,me,q,j),Re=le.getProgramCacheKey(Pe),Oe=te.programs;te.environment=T.isMeshStandardMaterial?q.environment:null,te.fog=q.fog,te.envMap=(T.isMeshStandardMaterial?Et:It).get(T.envMap||te.environment),te.envMapRotation=te.environment!==null&&T.envMap===null?q.environmentRotation:T.envMapRotation,Oe===void 0&&(T.addEventListener("dispose",ue),Oe=new Map,te.programs=Oe);let ye=Oe.get(Re);if(ye!==void 0){if(te.currentProgram===ye&&te.lightsStateVersion===be)return Fa(T,Pe),ye}else Pe.uniforms=le.getUniforms(T),T.onBeforeCompile(Pe,_),ye=le.acquireProgram(Pe,Re),Oe.set(Re,ye),te.uniforms=Pe.uniforms;let Ce=te.uniforms;return(!T.isShaderMaterial&&!T.isRawShaderMaterial||T.clipping===!0)&&(Ce.clippingPlanes=I.uniform),Fa(T,Pe),te.needsLights=vf(T),te.lightsStateVersion=be,te.needsLights&&(Ce.ambientLightColor.value=Y.state.ambient,Ce.lightProbe.value=Y.state.probe,Ce.directionalLights.value=Y.state.directional,Ce.directionalLightShadows.value=Y.state.directionalShadow,Ce.spotLights.value=Y.state.spot,Ce.spotLightShadows.value=Y.state.spotShadow,Ce.rectAreaLights.value=Y.state.rectArea,Ce.ltc_1.value=Y.state.rectAreaLTC1,Ce.ltc_2.value=Y.state.rectAreaLTC2,Ce.pointLights.value=Y.state.point,Ce.pointLightShadows.value=Y.state.pointShadow,Ce.hemisphereLights.value=Y.state.hemi,Ce.directionalShadowMap.value=Y.state.directionalShadowMap,Ce.directionalShadowMatrix.value=Y.state.directionalShadowMatrix,Ce.spotShadowMap.value=Y.state.spotShadowMap,Ce.spotLightMatrix.value=Y.state.spotLightMatrix,Ce.spotLightMap.value=Y.state.spotLightMap,Ce.pointShadowMap.value=Y.state.pointShadowMap,Ce.pointShadowMatrix.value=Y.state.pointShadowMatrix),te.currentProgram=ye,te.uniformsList=null,ye}function Ra(T){if(T.uniformsList===null){let q=T.currentProgram.getUniforms();T.uniformsList=Vo.seqWithValue(q.seq,T.uniforms)}return T.uniformsList}function Fa(T,q){let j=Fe.get(T);j.outputColorSpace=q.outputColorSpace,j.batching=q.batching,j.batchingColor=q.batchingColor,j.instancing=q.instancing,j.instancingColor=q.instancingColor,j.instancingMorph=q.instancingMorph,j.skinning=q.skinning,j.morphTargets=q.morphTargets,j.morphNormals=q.morphNormals,j.morphColors=q.morphColors,j.morphTargetsCount=q.morphTargetsCount,j.numClippingPlanes=q.numClippingPlanes,j.numIntersection=q.numClipIntersection,j.vertexAlphas=q.vertexAlphas,j.vertexTangents=q.vertexTangents,j.toneMapping=q.toneMapping}function gf(T,q,j,te,Y){q.isScene!==!0&&(q=xe),$e.resetTextureUnits();let me=q.fog,be=te.isMeshStandardMaterial?q.environment:null,Pe=D===null?_.outputColorSpace:D.isXRRenderTarget===!0?D.texture.colorSpace:Ai,Re=(te.isMeshStandardMaterial?Et:It).get(te.envMap||be),Oe=te.vertexColors===!0&&!!j.attributes.color&&j.attributes.color.itemSize===4,ye=!!j.attributes.tangent&&(!!te.normalMap||te.anisotropy>0),Ce=!!j.morphAttributes.position,tt=!!j.morphAttributes.normal,lt=!!j.morphAttributes.color,xt=Rr;te.toneMapped&&(D===null||D.isXRRenderTarget===!0)&&(xt=_.toneMapping);let _t=j.morphAttributes.position||j.morphAttributes.normal||j.morphAttributes.color,yt=_t!==void 0?_t.length:0,He=Fe.get(te),Ct=m.state.lights;if(ke===!0&&(re===!0||T!==w)){let un=T===w&&te.id===S;I.setState(te,T,un)}let dt=!1;te.version===He.__version?(He.needsLights&&He.lightsStateVersion!==Ct.state.version||He.outputColorSpace!==Pe||Y.isBatchedMesh&&He.batching===!1||!Y.isBatchedMesh&&He.batching===!0||Y.isBatchedMesh&&He.batchingColor===!0&&Y.colorTexture===null||Y.isBatchedMesh&&He.batchingColor===!1&&Y.colorTexture!==null||Y.isInstancedMesh&&He.instancing===!1||!Y.isInstancedMesh&&He.instancing===!0||Y.isSkinnedMesh&&He.skinning===!1||!Y.isSkinnedMesh&&He.skinning===!0||Y.isInstancedMesh&&He.instancingColor===!0&&Y.instanceColor===null||Y.isInstancedMesh&&He.instancingColor===!1&&Y.instanceColor!==null||Y.isInstancedMesh&&He.instancingMorph===!0&&Y.morphTexture===null||Y.isInstancedMesh&&He.instancingMorph===!1&&Y.morphTexture!==null||He.envMap!==Re||te.fog===!0&&He.fog!==me||He.numClippingPlanes!==void 0&&(He.numClippingPlanes!==I.numPlanes||He.numIntersection!==I.numIntersection)||He.vertexAlphas!==Oe||He.vertexTangents!==ye||He.morphTargets!==Ce||He.morphNormals!==tt||He.morphColors!==lt||He.toneMapping!==xt||He.morphTargetsCount!==yt)&&(dt=!0):(dt=!0,He.__version=te.version);let wn=He.currentProgram;dt===!0&&(wn=so(te,q,Y));let ao=!1,bn=!1,cs=!1,Tt=wn.getUniforms(),Ln=He.uniforms;if(Ae.useProgram(wn.program)&&(ao=!0,bn=!0,cs=!0),te.id!==S&&(S=te.id,bn=!0),ao||w!==T){Ae.buffers.depth.getReversed()&&T.reversedDepth!==!0&&(T._reversedDepth=!0,T.updateProjectionMatrix()),Tt.setValue(N,"projectionMatrix",T.projectionMatrix),Tt.setValue(N,"viewMatrix",T.matrixWorldInverse);let mn=Tt.map.cameraPosition;mn!==void 0&&mn.setValue(N,Se.setFromMatrixPosition(T.matrixWorld)),Be.logarithmicDepthBuffer&&Tt.setValue(N,"logDepthBufFC",2/(Math.log(T.far+1)/Math.LN2)),(te.isMeshPhongMaterial||te.isMeshToonMaterial||te.isMeshLambertMaterial||te.isMeshBasicMaterial||te.isMeshStandardMaterial||te.isShaderMaterial)&&Tt.setValue(N,"isOrthographic",T.isOrthographicCamera===!0),w!==T&&(w=T,bn=!0,cs=!0)}if(Y.isSkinnedMesh){Tt.setOptional(N,Y,"bindMatrix"),Tt.setOptional(N,Y,"bindMatrixInverse");let un=Y.skeleton;un&&(un.boneTexture===null&&un.computeBoneTexture(),Tt.setValue(N,"boneTexture",un.boneTexture,$e))}Y.isBatchedMesh&&(Tt.setOptional(N,Y,"batchingTexture"),Tt.setValue(N,"batchingTexture",Y._matricesTexture,$e),Tt.setOptional(N,Y,"batchingIdTexture"),Tt.setValue(N,"batchingIdTexture",Y._indirectTexture,$e),Tt.setOptional(N,Y,"batchingColorTexture"),Y._colorsTexture!==null&&Tt.setValue(N,"batchingColorTexture",Y._colorsTexture,$e));let Bn=j.morphAttributes;if((Bn.position!==void 0||Bn.normal!==void 0||Bn.color!==void 0)&&G.update(Y,j,wn),(bn||He.receiveShadow!==Y.receiveShadow)&&(He.receiveShadow=Y.receiveShadow,Tt.setValue(N,"receiveShadow",Y.receiveShadow)),te.isMeshGouraudMaterial&&te.envMap!==null&&(Ln.envMap.value=Re,Ln.flipEnvMap.value=Re.isCubeTexture&&Re.isRenderTargetTexture===!1?-1:1),te.isMeshStandardMaterial&&te.envMap===null&&q.environment!==null&&(Ln.envMapIntensity.value=q.environmentIntensity),bn&&(Tt.setValue(N,"toneMappingExposure",_.toneMappingExposure),He.needsLights&&xf(Ln,cs),me&&te.fog===!0&&de.refreshFogUniforms(Ln,me),de.refreshMaterialUniforms(Ln,te,H,J,m.state.transmissionRenderTarget[T.id]),Vo.upload(N,Ra(He),Ln,$e)),te.isShaderMaterial&&te.uniformsNeedUpdate===!0&&(Vo.upload(N,Ra(He),Ln,$e),te.uniformsNeedUpdate=!1),te.isSpriteMaterial&&Tt.setValue(N,"center",Y.center),Tt.setValue(N,"modelViewMatrix",Y.modelViewMatrix),Tt.setValue(N,"normalMatrix",Y.normalMatrix),Tt.setValue(N,"modelMatrix",Y.matrixWorld),te.isShaderMaterial||te.isRawShaderMaterial){let un=te.uniformsGroups;for(let mn=0,Sf=un.length;mn<Sf;mn++){let _i=un[mn];Q.update(_i,wn),Q.bind(_i,wn)}}return wn}function xf(T,q){T.ambientLightColor.needsUpdate=q,T.lightProbe.needsUpdate=q,T.directionalLights.needsUpdate=q,T.directionalLightShadows.needsUpdate=q,T.pointLights.needsUpdate=q,T.pointLightShadows.needsUpdate=q,T.spotLights.needsUpdate=q,T.spotLightShadows.needsUpdate=q,T.rectAreaLights.needsUpdate=q,T.hemisphereLights.needsUpdate=q}function vf(T){return T.isMeshLambertMaterial||T.isMeshToonMaterial||T.isMeshPhongMaterial||T.isMeshStandardMaterial||T.isShadowMaterial||T.isShaderMaterial&&T.lights===!0}this.getActiveCubeFace=function(){return y},this.getActiveMipmapLevel=function(){return E},this.getRenderTarget=function(){return D},this.setRenderTargetTextures=function(T,q,j){let te=Fe.get(T);te.__autoAllocateDepthBuffer=T.resolveDepthBuffer===!1,te.__autoAllocateDepthBuffer===!1&&(te.__useRenderToTexture=!1),Fe.get(T.texture).__webglTexture=q,Fe.get(T.depthTexture).__webglTexture=te.__autoAllocateDepthBuffer?void 0:j,te.__hasExternalTextures=!0},this.setRenderTargetFramebuffer=function(T,q){let j=Fe.get(T);j.__webglFramebuffer=q,j.__useDefaultFramebuffer=q===void 0};let _f=N.createFramebuffer();this.setRenderTarget=function(T,q=0,j=0){D=T,y=q,E=j;let te=!0,Y=null,me=!1,be=!1;if(T){let Re=Fe.get(T);if(Re.__useDefaultFramebuffer!==void 0)Ae.bindFramebuffer(N.FRAMEBUFFER,null),te=!1;else if(Re.__webglFramebuffer===void 0)$e.setupRenderTarget(T);else if(Re.__hasExternalTextures)$e.rebindTextures(T,Fe.get(T.texture).__webglTexture,Fe.get(T.depthTexture).__webglTexture);else if(T.depthBuffer){let Ce=T.depthTexture;if(Re.__boundDepthTexture!==Ce){if(Ce!==null&&Fe.has(Ce)&&(T.width!==Ce.image.width||T.height!==Ce.image.height))throw new Error("WebGLRenderTarget: Attached DepthTexture is initialized to the incorrect size.");$e.setupDepthRenderbuffer(T)}}let Oe=T.texture;(Oe.isData3DTexture||Oe.isDataArrayTexture||Oe.isCompressedArrayTexture)&&(be=!0);let ye=Fe.get(T).__webglFramebuffer;T.isWebGLCubeRenderTarget?(Array.isArray(ye[q])?Y=ye[q][j]:Y=ye[q],me=!0):T.samples>0&&$e.useMultisampledRTT(T)===!1?Y=Fe.get(T).__webglMultisampledFramebuffer:Array.isArray(ye)?Y=ye[j]:Y=ye,C.copy(T.viewport),F.copy(T.scissor),O=T.scissorTest}else C.copy(ge).multiplyScalar(H).floor(),F.copy(Te).multiplyScalar(H).floor(),O=ze;if(j!==0&&(Y=_f),Ae.bindFramebuffer(N.FRAMEBUFFER,Y)&&te&&Ae.drawBuffers(T,Y),Ae.viewport(C),Ae.scissor(F),Ae.setScissorTest(O),me){let Re=Fe.get(T.texture);N.framebufferTexture2D(N.FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_CUBE_MAP_POSITIVE_X+q,Re.__webglTexture,j)}else if(be){let Re=q;for(let Oe=0;Oe<T.textures.length;Oe++){let ye=Fe.get(T.textures[Oe]);N.framebufferTextureLayer(N.FRAMEBUFFER,N.COLOR_ATTACHMENT0+Oe,ye.__webglTexture,j,Re)}}else if(T!==null&&j!==0){let Re=Fe.get(T.texture);N.framebufferTexture2D(N.FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_2D,Re.__webglTexture,j)}S=-1},this.readRenderTargetPixels=function(T,q,j,te,Y,me,be,Pe=0){if(!(T&&T.isWebGLRenderTarget)){console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");return}let Re=Fe.get(T).__webglFramebuffer;if(T.isWebGLCubeRenderTarget&&be!==void 0&&(Re=Re[be]),Re){Ae.bindFramebuffer(N.FRAMEBUFFER,Re);try{let Oe=T.textures[Pe],ye=Oe.format,Ce=Oe.type;if(!Be.textureFormatReadable(ye)){console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in RGBA or implementation defined format.");return}if(!Be.textureTypeReadable(Ce)){console.error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not in UnsignedByteType or implementation defined type.");return}q>=0&&q<=T.width-te&&j>=0&&j<=T.height-Y&&(T.textures.length>1&&N.readBuffer(N.COLOR_ATTACHMENT0+Pe),N.readPixels(q,j,te,Y,$.convert(ye),$.convert(Ce),me))}finally{let Oe=D!==null?Fe.get(D).__webglFramebuffer:null;Ae.bindFramebuffer(N.FRAMEBUFFER,Oe)}}},this.readRenderTargetPixelsAsync=async function(T,q,j,te,Y,me,be,Pe=0){if(!(T&&T.isWebGLRenderTarget))throw new Error("THREE.WebGLRenderer.readRenderTargetPixels: renderTarget is not THREE.WebGLRenderTarget.");let Re=Fe.get(T).__webglFramebuffer;if(T.isWebGLCubeRenderTarget&&be!==void 0&&(Re=Re[be]),Re)if(q>=0&&q<=T.width-te&&j>=0&&j<=T.height-Y){Ae.bindFramebuffer(N.FRAMEBUFFER,Re);let Oe=T.textures[Pe],ye=Oe.format,Ce=Oe.type;if(!Be.textureFormatReadable(ye))throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in RGBA or implementation defined format.");if(!Be.textureTypeReadable(Ce))throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: renderTarget is not in UnsignedByteType or implementation defined type.");let tt=N.createBuffer();N.bindBuffer(N.PIXEL_PACK_BUFFER,tt),N.bufferData(N.PIXEL_PACK_BUFFER,me.byteLength,N.STREAM_READ),T.textures.length>1&&N.readBuffer(N.COLOR_ATTACHMENT0+Pe),N.readPixels(q,j,te,Y,$.convert(ye),$.convert(Ce),0);let lt=D!==null?Fe.get(D).__webglFramebuffer:null;Ae.bindFramebuffer(N.FRAMEBUFFER,lt);let xt=N.fenceSync(N.SYNC_GPU_COMMANDS_COMPLETE,0);return N.flush(),await ug(N,xt,4),N.bindBuffer(N.PIXEL_PACK_BUFFER,tt),N.getBufferSubData(N.PIXEL_PACK_BUFFER,0,me),N.deleteBuffer(tt),N.deleteSync(xt),me}else throw new Error("THREE.WebGLRenderer.readRenderTargetPixelsAsync: requested read bounds are out of range.")},this.copyFramebufferToTexture=function(T,q=null,j=0){let te=Math.pow(2,-j),Y=Math.floor(T.image.width*te),me=Math.floor(T.image.height*te),be=q!==null?q.x:0,Pe=q!==null?q.y:0;$e.setTexture2D(T,0),N.copyTexSubImage2D(N.TEXTURE_2D,j,0,0,be,Pe,Y,me),Ae.unbindTexture()};let yf=N.createFramebuffer(),Mf=N.createFramebuffer();this.copyTextureToTexture=function(T,q,j=null,te=null,Y=0,me=null){me===null&&(Y!==0?(Eo("WebGLRenderer: copyTextureToTexture function signature has changed to support src and dst mipmap levels."),me=Y,Y=0):me=0);let be,Pe,Re,Oe,ye,Ce,tt,lt,xt,_t=T.isCompressedTexture?T.mipmaps[me]:T.image;if(j!==null)be=j.max.x-j.min.x,Pe=j.max.y-j.min.y,Re=j.isBox3?j.max.z-j.min.z:1,Oe=j.min.x,ye=j.min.y,Ce=j.isBox3?j.min.z:0;else{let Bn=Math.pow(2,-Y);be=Math.floor(_t.width*Bn),Pe=Math.floor(_t.height*Bn),T.isDataArrayTexture?Re=_t.depth:T.isData3DTexture?Re=Math.floor(_t.depth*Bn):Re=1,Oe=0,ye=0,Ce=0}te!==null?(tt=te.x,lt=te.y,xt=te.z):(tt=0,lt=0,xt=0);let yt=$.convert(q.format),He=$.convert(q.type),Ct;q.isData3DTexture?($e.setTexture3D(q,0),Ct=N.TEXTURE_3D):q.isDataArrayTexture||q.isCompressedArrayTexture?($e.setTexture2DArray(q,0),Ct=N.TEXTURE_2D_ARRAY):($e.setTexture2D(q,0),Ct=N.TEXTURE_2D),N.pixelStorei(N.UNPACK_FLIP_Y_WEBGL,q.flipY),N.pixelStorei(N.UNPACK_PREMULTIPLY_ALPHA_WEBGL,q.premultiplyAlpha),N.pixelStorei(N.UNPACK_ALIGNMENT,q.unpackAlignment);let dt=N.getParameter(N.UNPACK_ROW_LENGTH),wn=N.getParameter(N.UNPACK_IMAGE_HEIGHT),ao=N.getParameter(N.UNPACK_SKIP_PIXELS),bn=N.getParameter(N.UNPACK_SKIP_ROWS),cs=N.getParameter(N.UNPACK_SKIP_IMAGES);N.pixelStorei(N.UNPACK_ROW_LENGTH,_t.width),N.pixelStorei(N.UNPACK_IMAGE_HEIGHT,_t.height),N.pixelStorei(N.UNPACK_SKIP_PIXELS,Oe),N.pixelStorei(N.UNPACK_SKIP_ROWS,ye),N.pixelStorei(N.UNPACK_SKIP_IMAGES,Ce);let Tt=T.isDataArrayTexture||T.isData3DTexture,Ln=q.isDataArrayTexture||q.isData3DTexture;if(T.isDepthTexture){let Bn=Fe.get(T),un=Fe.get(q),mn=Fe.get(Bn.__renderTarget),Sf=Fe.get(un.__renderTarget);Ae.bindFramebuffer(N.READ_FRAMEBUFFER,mn.__webglFramebuffer),Ae.bindFramebuffer(N.DRAW_FRAMEBUFFER,Sf.__webglFramebuffer);for(let _i=0;_i<Re;_i++)Tt&&(N.framebufferTextureLayer(N.READ_FRAMEBUFFER,N.COLOR_ATTACHMENT0,Fe.get(T).__webglTexture,Y,Ce+_i),N.framebufferTextureLayer(N.DRAW_FRAMEBUFFER,N.COLOR_ATTACHMENT0,Fe.get(q).__webglTexture,me,xt+_i)),N.blitFramebuffer(Oe,ye,be,Pe,tt,lt,be,Pe,N.DEPTH_BUFFER_BIT,N.NEAREST);Ae.bindFramebuffer(N.READ_FRAMEBUFFER,null),Ae.bindFramebuffer(N.DRAW_FRAMEBUFFER,null)}else if(Y!==0||T.isRenderTargetTexture||Fe.has(T)){let Bn=Fe.get(T),un=Fe.get(q);Ae.bindFramebuffer(N.READ_FRAMEBUFFER,yf),Ae.bindFramebuffer(N.DRAW_FRAMEBUFFER,Mf);for(let mn=0;mn<Re;mn++)Tt?N.framebufferTextureLayer(N.READ_FRAMEBUFFER,N.COLOR_ATTACHMENT0,Bn.__webglTexture,Y,Ce+mn):N.framebufferTexture2D(N.READ_FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_2D,Bn.__webglTexture,Y),Ln?N.framebufferTextureLayer(N.DRAW_FRAMEBUFFER,N.COLOR_ATTACHMENT0,un.__webglTexture,me,xt+mn):N.framebufferTexture2D(N.DRAW_FRAMEBUFFER,N.COLOR_ATTACHMENT0,N.TEXTURE_2D,un.__webglTexture,me),Y!==0?N.blitFramebuffer(Oe,ye,be,Pe,tt,lt,be,Pe,N.COLOR_BUFFER_BIT,N.NEAREST):Ln?N.copyTexSubImage3D(Ct,me,tt,lt,xt+mn,Oe,ye,be,Pe):N.copyTexSubImage2D(Ct,me,tt,lt,Oe,ye,be,Pe);Ae.bindFramebuffer(N.READ_FRAMEBUFFER,null),Ae.bindFramebuffer(N.DRAW_FRAMEBUFFER,null)}else Ln?T.isDataTexture||T.isData3DTexture?N.texSubImage3D(Ct,me,tt,lt,xt,be,Pe,Re,yt,He,_t.data):q.isCompressedArrayTexture?N.compressedTexSubImage3D(Ct,me,tt,lt,xt,be,Pe,Re,yt,_t.data):N.texSubImage3D(Ct,me,tt,lt,xt,be,Pe,Re,yt,He,_t):T.isDataTexture?N.texSubImage2D(N.TEXTURE_2D,me,tt,lt,be,Pe,yt,He,_t.data):T.isCompressedTexture?N.compressedTexSubImage2D(N.TEXTURE_2D,me,tt,lt,_t.width,_t.height,yt,_t.data):N.texSubImage2D(N.TEXTURE_2D,me,tt,lt,be,Pe,yt,He,_t);N.pixelStorei(N.UNPACK_ROW_LENGTH,dt),N.pixelStorei(N.UNPACK_IMAGE_HEIGHT,wn),N.pixelStorei(N.UNPACK_SKIP_PIXELS,ao),N.pixelStorei(N.UNPACK_SKIP_ROWS,bn),N.pixelStorei(N.UNPACK_SKIP_IMAGES,cs),me===0&&q.generateMipmaps&&N.generateMipmap(Ct),Ae.unbindTexture()},this.initRenderTarget=function(T){Fe.get(T).__webglFramebuffer===void 0&&$e.setupRenderTarget(T)},this.initTexture=function(T){T.isCubeTexture?$e.setTextureCube(T,0):T.isData3DTexture?$e.setTexture3D(T,0):T.isDataArrayTexture||T.isCompressedArrayTexture?$e.setTexture2DArray(T,0):$e.setTexture2D(T,0),Ae.unbindTexture()},this.resetState=function(){y=0,E=0,D=null,Ae.reset(),ee.reset()},typeof __THREE_DEVTOOLS__<"u"&&__THREE_DEVTOOLS__.dispatchEvent(new CustomEvent("observe",{detail:this}))}get coordinateSystem(){return $n}get outputColorSpace(){return this._outputColorSpace}set outputColorSpace(e){this._outputColorSpace=e;let n=this.getContext();n.drawingBufferColorSpace=ct._getDrawingBufferColorSpace(e),n.unpackColorSpace=ct._getUnpackColorSpace()}};var kg={type:"change"},Xh={type:"start"},Hg={type:"end"},Fl=new Ti,Vg=new On,Yb=Math.cos(70*wh.DEG2RAD),Ot=new k,gn=2*Math.PI,vt={NONE:-1,ROTATE:0,DOLLY:1,PAN:2,TOUCH_ROTATE:3,TOUCH_PAN:4,TOUCH_DOLLY_PAN:5,TOUCH_DOLLY_ROTATE:6},qh=1e-6,Pl=class extends Ws{constructor(e,n=null){super(e,n),this.state=vt.NONE,this.target=new k,this.cursor=new k,this.minDistance=0,this.maxDistance=1/0,this.minZoom=0,this.maxZoom=1/0,this.minTargetRadius=0,this.maxTargetRadius=1/0,this.minPolarAngle=0,this.maxPolarAngle=Math.PI,this.minAzimuthAngle=-1/0,this.maxAzimuthAngle=1/0,this.enableDamping=!1,this.dampingFactor=.05,this.enableZoom=!0,this.zoomSpeed=1,this.enableRotate=!0,this.rotateSpeed=1,this.keyRotateSpeed=1,this.enablePan=!0,this.panSpeed=1,this.screenSpacePanning=!0,this.keyPanSpeed=7,this.zoomToCursor=!1,this.autoRotate=!1,this.autoRotateSpeed=2,this.keys={LEFT:"ArrowLeft",UP:"ArrowUp",RIGHT:"ArrowRight",BOTTOM:"ArrowDown"},this.mouseButtons={LEFT:jr.ROTATE,MIDDLE:jr.DOLLY,RIGHT:jr.PAN},this.touches={ONE:ei.ROTATE,TWO:ei.DOLLY_PAN},this.target0=this.target.clone(),this.position0=this.object.position.clone(),this.zoom0=this.object.zoom,this._domElementKeyEvents=null,this._lastPosition=new k,this._lastQuaternion=new kn,this._lastTargetPosition=new k,this._quat=new kn().setFromUnitVectors(e.up,new k(0,1,0)),this._quatInverse=this._quat.clone().invert(),this._spherical=new Io,this._sphericalDelta=new Io,this._scale=1,this._panOffset=new k,this._rotateStart=new Ie,this._rotateEnd=new Ie,this._rotateDelta=new Ie,this._panStart=new Ie,this._panEnd=new Ie,this._panDelta=new Ie,this._dollyStart=new Ie,this._dollyEnd=new Ie,this._dollyDelta=new Ie,this._dollyDirection=new k,this._mouse=new Ie,this._performCursorZoom=!1,this._pointers=[],this._pointerPositions={},this._controlActive=!1,this._onPointerMove=$b.bind(this),this._onPointerDown=Zb.bind(this),this._onPointerUp=Jb.bind(this),this._onContextMenu=rE.bind(this),this._onMouseWheel=jb.bind(this),this._onKeyDown=eE.bind(this),this._onTouchStart=tE.bind(this),this._onTouchMove=nE.bind(this),this._onMouseDown=Kb.bind(this),this._onMouseMove=Qb.bind(this),this._interceptControlDown=iE.bind(this),this._interceptControlUp=oE.bind(this),this.domElement!==null&&this.connect(this.domElement),this.update()}connect(e){super.connect(e),this.domElement.addEventListener("pointerdown",this._onPointerDown),this.domElement.addEventListener("pointercancel",this._onPointerUp),this.domElement.addEventListener("contextmenu",this._onContextMenu),this.domElement.addEventListener("wheel",this._onMouseWheel,{passive:!1}),this.domElement.getRootNode().addEventListener("keydown",this._interceptControlDown,{passive:!0,capture:!0}),this.domElement.style.touchAction="none"}disconnect(){this.domElement.removeEventListener("pointerdown",this._onPointerDown),this.domElement.removeEventListener("pointermove",this._onPointerMove),this.domElement.removeEventListener("pointerup",this._onPointerUp),this.domElement.removeEventListener("pointercancel",this._onPointerUp),this.domElement.removeEventListener("wheel",this._onMouseWheel),this.domElement.removeEventListener("contextmenu",this._onContextMenu),this.stopListenToKeyEvents(),this.domElement.getRootNode().removeEventListener("keydown",this._interceptControlDown,{capture:!0}),this.domElement.style.touchAction="auto"}dispose(){this.disconnect()}getPolarAngle(){return this._spherical.phi}getAzimuthalAngle(){return this._spherical.theta}getDistance(){return this.object.position.distanceTo(this.target)}listenToKeyEvents(e){e.addEventListener("keydown",this._onKeyDown),this._domElementKeyEvents=e}stopListenToKeyEvents(){this._domElementKeyEvents!==null&&(this._domElementKeyEvents.removeEventListener("keydown",this._onKeyDown),this._domElementKeyEvents=null)}saveState(){this.target0.copy(this.target),this.position0.copy(this.object.position),this.zoom0=this.object.zoom}reset(){this.target.copy(this.target0),this.object.position.copy(this.position0),this.object.zoom=this.zoom0,this.object.updateProjectionMatrix(),this.dispatchEvent(kg),this.update(),this.state=vt.NONE}update(e=null){let n=this.object.position;Ot.copy(n).sub(this.target),Ot.applyQuaternion(this._quat),this._spherical.setFromVector3(Ot),this.autoRotate&&this.state===vt.NONE&&this._rotateLeft(this._getAutoRotationAngle(e)),this.enableDamping?(this._spherical.theta+=this._sphericalDelta.theta*this.dampingFactor,this._spherical.phi+=this._sphericalDelta.phi*this.dampingFactor):(this._spherical.theta+=this._sphericalDelta.theta,this._spherical.phi+=this._sphericalDelta.phi);let r=this.minAzimuthAngle,i=this.maxAzimuthAngle;isFinite(r)&&isFinite(i)&&(r<-Math.PI?r+=gn:r>Math.PI&&(r-=gn),i<-Math.PI?i+=gn:i>Math.PI&&(i-=gn),r<=i?this._spherical.theta=Math.max(r,Math.min(i,this._spherical.theta)):this._spherical.theta=this._spherical.theta>(r+i)/2?Math.max(r,this._spherical.theta):Math.min(i,this._spherical.theta)),this._spherical.phi=Math.max(this.minPolarAngle,Math.min(this.maxPolarAngle,this._spherical.phi)),this._spherical.makeSafe(),this.enableDamping===!0?this.target.addScaledVector(this._panOffset,this.dampingFactor):this.target.add(this._panOffset),this.target.sub(this.cursor),this.target.clampLength(this.minTargetRadius,this.maxTargetRadius),this.target.add(this.cursor);let o=!1;if(this.zoomToCursor&&this._performCursorZoom||this.object.isOrthographicCamera)this._spherical.radius=this._clampDistance(this._spherical.radius);else{let s=this._spherical.radius;this._spherical.radius=this._clampDistance(this._spherical.radius*this._scale),o=s!=this._spherical.radius}if(Ot.setFromSpherical(this._spherical),Ot.applyQuaternion(this._quatInverse),n.copy(this.target).add(Ot),this.object.lookAt(this.target),this.enableDamping===!0?(this._sphericalDelta.theta*=1-this.dampingFactor,this._sphericalDelta.phi*=1-this.dampingFactor,this._panOffset.multiplyScalar(1-this.dampingFactor)):(this._sphericalDelta.set(0,0,0),this._panOffset.set(0,0,0)),this.zoomToCursor&&this._performCursorZoom){let s=null;if(this.object.isPerspectiveCamera){let a=Ot.length();s=this._clampDistance(a*this._scale);let l=a-s;this.object.position.addScaledVector(this._dollyDirection,l),this.object.updateMatrixWorld(),o=!!l}else if(this.object.isOrthographicCamera){let a=new k(this._mouse.x,this._mouse.y,0);a.unproject(this.object);let l=this.object.zoom;this.object.zoom=Math.max(this.minZoom,Math.min(this.maxZoom,this.object.zoom/this._scale)),this.object.updateProjectionMatrix(),o=l!==this.object.zoom;let u=new k(this._mouse.x,this._mouse.y,0);u.unproject(this.object),this.object.position.sub(u).add(a),this.object.updateMatrixWorld(),s=Ot.length()}else console.warn("WARNING: OrbitControls.js encountered an unknown camera type - zoom to cursor disabled."),this.zoomToCursor=!1;s!==null&&(this.screenSpacePanning?this.target.set(0,0,-1).transformDirection(this.object.matrix).multiplyScalar(s).add(this.object.position):(Fl.origin.copy(this.object.position),Fl.direction.set(0,0,-1).transformDirection(this.object.matrix),Math.abs(this.object.up.dot(Fl.direction))<Yb?this.object.lookAt(this.target):(Vg.setFromNormalAndCoplanarPoint(this.object.up,this.target),Fl.intersectPlane(Vg,this.target))))}else if(this.object.isOrthographicCamera){let s=this.object.zoom;this.object.zoom=Math.max(this.minZoom,Math.min(this.maxZoom,this.object.zoom/this._scale)),s!==this.object.zoom&&(this.object.updateProjectionMatrix(),o=!0)}return this._scale=1,this._performCursorZoom=!1,o||this._lastPosition.distanceToSquared(this.object.position)>qh||8*(1-this._lastQuaternion.dot(this.object.quaternion))>qh||this._lastTargetPosition.distanceToSquared(this.target)>qh?(this.dispatchEvent(kg),this._lastPosition.copy(this.object.position),this._lastQuaternion.copy(this.object.quaternion),this._lastTargetPosition.copy(this.target),!0):!1}_getAutoRotationAngle(e){return e!==null?gn/60*this.autoRotateSpeed*e:gn/60/60*this.autoRotateSpeed}_getZoomScale(e){let n=Math.abs(e*.01);return Math.pow(.95,this.zoomSpeed*n)}_rotateLeft(e){this._sphericalDelta.theta-=e}_rotateUp(e){this._sphericalDelta.phi-=e}_panLeft(e,n){Ot.setFromMatrixColumn(n,0),Ot.multiplyScalar(-e),this._panOffset.add(Ot)}_panUp(e,n){this.screenSpacePanning===!0?Ot.setFromMatrixColumn(n,1):(Ot.setFromMatrixColumn(n,0),Ot.crossVectors(this.object.up,Ot)),Ot.multiplyScalar(e),this._panOffset.add(Ot)}_pan(e,n){let r=this.domElement;if(this.object.isPerspectiveCamera){let i=this.object.position;Ot.copy(i).sub(this.target);let o=Ot.length();o*=Math.tan(this.object.fov/2*Math.PI/180),this._panLeft(2*e*o/r.clientHeight,this.object.matrix),this._panUp(2*n*o/r.clientHeight,this.object.matrix)}else this.object.isOrthographicCamera?(this._panLeft(e*(this.object.right-this.object.left)/this.object.zoom/r.clientWidth,this.object.matrix),this._panUp(n*(this.object.top-this.object.bottom)/this.object.zoom/r.clientHeight,this.object.matrix)):(console.warn("WARNING: OrbitControls.js encountered an unknown camera type - pan disabled."),this.enablePan=!1)}_dollyOut(e){this.object.isPerspectiveCamera||this.object.isOrthographicCamera?this._scale/=e:(console.warn("WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled."),this.enableZoom=!1)}_dollyIn(e){this.object.isPerspectiveCamera||this.object.isOrthographicCamera?this._scale*=e:(console.warn("WARNING: OrbitControls.js encountered an unknown camera type - dolly/zoom disabled."),this.enableZoom=!1)}_updateZoomParameters(e,n){if(!this.zoomToCursor)return;this._performCursorZoom=!0;let r=this.domElement.getBoundingClientRect(),i=e-r.left,o=n-r.top,s=r.width,a=r.height;this._mouse.x=i/s*2-1,this._mouse.y=-(o/a)*2+1,this._dollyDirection.set(this._mouse.x,this._mouse.y,1).unproject(this.object).sub(this.object.position).normalize()}_clampDistance(e){return Math.max(this.minDistance,Math.min(this.maxDistance,e))}_handleMouseDownRotate(e){this._rotateStart.set(e.clientX,e.clientY)}_handleMouseDownDolly(e){this._updateZoomParameters(e.clientX,e.clientX),this._dollyStart.set(e.clientX,e.clientY)}_handleMouseDownPan(e){this._panStart.set(e.clientX,e.clientY)}_handleMouseMoveRotate(e){this._rotateEnd.set(e.clientX,e.clientY),this._rotateDelta.subVectors(this._rotateEnd,this._rotateStart).multiplyScalar(this.rotateSpeed);let n=this.domElement;this._rotateLeft(gn*this._rotateDelta.x/n.clientHeight),this._rotateUp(gn*this._rotateDelta.y/n.clientHeight),this._rotateStart.copy(this._rotateEnd),this.update()}_handleMouseMoveDolly(e){this._dollyEnd.set(e.clientX,e.clientY),this._dollyDelta.subVectors(this._dollyEnd,this._dollyStart),this._dollyDelta.y>0?this._dollyOut(this._getZoomScale(this._dollyDelta.y)):this._dollyDelta.y<0&&this._dollyIn(this._getZoomScale(this._dollyDelta.y)),this._dollyStart.copy(this._dollyEnd),this.update()}_handleMouseMovePan(e){this._panEnd.set(e.clientX,e.clientY),this._panDelta.subVectors(this._panEnd,this._panStart).multiplyScalar(this.panSpeed),this._pan(this._panDelta.x,this._panDelta.y),this._panStart.copy(this._panEnd),this.update()}_handleMouseWheel(e){this._updateZoomParameters(e.clientX,e.clientY),e.deltaY<0?this._dollyIn(this._getZoomScale(e.deltaY)):e.deltaY>0&&this._dollyOut(this._getZoomScale(e.deltaY)),this.update()}_handleKeyDown(e){let n=!1;switch(e.code){case this.keys.UP:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateUp(gn*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(0,this.keyPanSpeed),n=!0;break;case this.keys.BOTTOM:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateUp(-gn*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(0,-this.keyPanSpeed),n=!0;break;case this.keys.LEFT:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateLeft(gn*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(this.keyPanSpeed,0),n=!0;break;case this.keys.RIGHT:e.ctrlKey||e.metaKey||e.shiftKey?this.enableRotate&&this._rotateLeft(-gn*this.keyRotateSpeed/this.domElement.clientHeight):this.enablePan&&this._pan(-this.keyPanSpeed,0),n=!0;break}n&&(e.preventDefault(),this.update())}_handleTouchStartRotate(e){if(this._pointers.length===1)this._rotateStart.set(e.pageX,e.pageY);else{let n=this._getSecondPointerPosition(e),r=.5*(e.pageX+n.x),i=.5*(e.pageY+n.y);this._rotateStart.set(r,i)}}_handleTouchStartPan(e){if(this._pointers.length===1)this._panStart.set(e.pageX,e.pageY);else{let n=this._getSecondPointerPosition(e),r=.5*(e.pageX+n.x),i=.5*(e.pageY+n.y);this._panStart.set(r,i)}}_handleTouchStartDolly(e){let n=this._getSecondPointerPosition(e),r=e.pageX-n.x,i=e.pageY-n.y,o=Math.sqrt(r*r+i*i);this._dollyStart.set(0,o)}_handleTouchStartDollyPan(e){this.enableZoom&&this._handleTouchStartDolly(e),this.enablePan&&this._handleTouchStartPan(e)}_handleTouchStartDollyRotate(e){this.enableZoom&&this._handleTouchStartDolly(e),this.enableRotate&&this._handleTouchStartRotate(e)}_handleTouchMoveRotate(e){if(this._pointers.length==1)this._rotateEnd.set(e.pageX,e.pageY);else{let r=this._getSecondPointerPosition(e),i=.5*(e.pageX+r.x),o=.5*(e.pageY+r.y);this._rotateEnd.set(i,o)}this._rotateDelta.subVectors(this._rotateEnd,this._rotateStart).multiplyScalar(this.rotateSpeed);let n=this.domElement;this._rotateLeft(gn*this._rotateDelta.x/n.clientHeight),this._rotateUp(gn*this._rotateDelta.y/n.clientHeight),this._rotateStart.copy(this._rotateEnd)}_handleTouchMovePan(e){if(this._pointers.length===1)this._panEnd.set(e.pageX,e.pageY);else{let n=this._getSecondPointerPosition(e),r=.5*(e.pageX+n.x),i=.5*(e.pageY+n.y);this._panEnd.set(r,i)}this._panDelta.subVectors(this._panEnd,this._panStart).multiplyScalar(this.panSpeed),this._pan(this._panDelta.x,this._panDelta.y),this._panStart.copy(this._panEnd)}_handleTouchMoveDolly(e){let n=this._getSecondPointerPosition(e),r=e.pageX-n.x,i=e.pageY-n.y,o=Math.sqrt(r*r+i*i);this._dollyEnd.set(0,o),this._dollyDelta.set(0,Math.pow(this._dollyEnd.y/this._dollyStart.y,this.zoomSpeed)),this._dollyOut(this._dollyDelta.y),this._dollyStart.copy(this._dollyEnd);let s=(e.pageX+n.x)*.5,a=(e.pageY+n.y)*.5;this._updateZoomParameters(s,a)}_handleTouchMoveDollyPan(e){this.enableZoom&&this._handleTouchMoveDolly(e),this.enablePan&&this._handleTouchMovePan(e)}_handleTouchMoveDollyRotate(e){this.enableZoom&&this._handleTouchMoveDolly(e),this.enableRotate&&this._handleTouchMoveRotate(e)}_addPointer(e){this._pointers.push(e.pointerId)}_removePointer(e){delete this._pointerPositions[e.pointerId];for(let n=0;n<this._pointers.length;n++)if(this._pointers[n]==e.pointerId){this._pointers.splice(n,1);return}}_isTrackingPointer(e){for(let n=0;n<this._pointers.length;n++)if(this._pointers[n]==e.pointerId)return!0;return!1}_trackPointer(e){let n=this._pointerPositions[e.pointerId];n===void 0&&(n=new Ie,this._pointerPositions[e.pointerId]=n),n.set(e.pageX,e.pageY)}_getSecondPointerPosition(e){let n=e.pointerId===this._pointers[0]?this._pointers[1]:this._pointers[0];return this._pointerPositions[n]}_customWheelEvent(e){let n=e.deltaMode,r={clientX:e.clientX,clientY:e.clientY,deltaY:e.deltaY};switch(n){case 1:r.deltaY*=16;break;case 2:r.deltaY*=100;break}return e.ctrlKey&&!this._controlActive&&(r.deltaY*=10),r}};function Zb(t){this.enabled!==!1&&(this._pointers.length===0&&(this.domElement.setPointerCapture(t.pointerId),this.domElement.addEventListener("pointermove",this._onPointerMove),this.domElement.addEventListener("pointerup",this._onPointerUp)),!this._isTrackingPointer(t)&&(this._addPointer(t),t.pointerType==="touch"?this._onTouchStart(t):this._onMouseDown(t)))}function $b(t){this.enabled!==!1&&(t.pointerType==="touch"?this._onTouchMove(t):this._onMouseMove(t))}function Jb(t){switch(this._removePointer(t),this._pointers.length){case 0:this.domElement.releasePointerCapture(t.pointerId),this.domElement.removeEventListener("pointermove",this._onPointerMove),this.domElement.removeEventListener("pointerup",this._onPointerUp),this.dispatchEvent(Hg),this.state=vt.NONE;break;case 1:let e=this._pointers[0],n=this._pointerPositions[e];this._onTouchStart({pointerId:e,pageX:n.x,pageY:n.y});break}}function Kb(t){let e;switch(t.button){case 0:e=this.mouseButtons.LEFT;break;case 1:e=this.mouseButtons.MIDDLE;break;case 2:e=this.mouseButtons.RIGHT;break;default:e=-1}switch(e){case jr.DOLLY:if(this.enableZoom===!1)return;this._handleMouseDownDolly(t),this.state=vt.DOLLY;break;case jr.ROTATE:if(t.ctrlKey||t.metaKey||t.shiftKey){if(this.enablePan===!1)return;this._handleMouseDownPan(t),this.state=vt.PAN}else{if(this.enableRotate===!1)return;this._handleMouseDownRotate(t),this.state=vt.ROTATE}break;case jr.PAN:if(t.ctrlKey||t.metaKey||t.shiftKey){if(this.enableRotate===!1)return;this._handleMouseDownRotate(t),this.state=vt.ROTATE}else{if(this.enablePan===!1)return;this._handleMouseDownPan(t),this.state=vt.PAN}break;default:this.state=vt.NONE}this.state!==vt.NONE&&this.dispatchEvent(Xh)}function Qb(t){switch(this.state){case vt.ROTATE:if(this.enableRotate===!1)return;this._handleMouseMoveRotate(t);break;case vt.DOLLY:if(this.enableZoom===!1)return;this._handleMouseMoveDolly(t);break;case vt.PAN:if(this.enablePan===!1)return;this._handleMouseMovePan(t);break}}function jb(t){this.enabled===!1||this.enableZoom===!1||this.state!==vt.NONE||(t.preventDefault(),this.dispatchEvent(Xh),this._handleMouseWheel(this._customWheelEvent(t)),this.dispatchEvent(Hg))}function eE(t){this.enabled!==!1&&this._handleKeyDown(t)}function tE(t){switch(this._trackPointer(t),this._pointers.length){case 1:switch(this.touches.ONE){case ei.ROTATE:if(this.enableRotate===!1)return;this._handleTouchStartRotate(t),this.state=vt.TOUCH_ROTATE;break;case ei.PAN:if(this.enablePan===!1)return;this._handleTouchStartPan(t),this.state=vt.TOUCH_PAN;break;default:this.state=vt.NONE}break;case 2:switch(this.touches.TWO){case ei.DOLLY_PAN:if(this.enableZoom===!1&&this.enablePan===!1)return;this._handleTouchStartDollyPan(t),this.state=vt.TOUCH_DOLLY_PAN;break;case ei.DOLLY_ROTATE:if(this.enableZoom===!1&&this.enableRotate===!1)return;this._handleTouchStartDollyRotate(t),this.state=vt.TOUCH_DOLLY_ROTATE;break;default:this.state=vt.NONE}break;default:this.state=vt.NONE}this.state!==vt.NONE&&this.dispatchEvent(Xh)}function nE(t){switch(this._trackPointer(t),this.state){case vt.TOUCH_ROTATE:if(this.enableRotate===!1)return;this._handleTouchMoveRotate(t),this.update();break;case vt.TOUCH_PAN:if(this.enablePan===!1)return;this._handleTouchMovePan(t),this.update();break;case vt.TOUCH_DOLLY_PAN:if(this.enableZoom===!1&&this.enablePan===!1)return;this._handleTouchMoveDollyPan(t),this.update();break;case vt.TOUCH_DOLLY_ROTATE:if(this.enableZoom===!1&&this.enableRotate===!1)return;this._handleTouchMoveDollyRotate(t),this.update();break;default:this.state=vt.NONE}}function rE(t){this.enabled!==!1&&t.preventDefault()}function iE(t){t.key==="Control"&&(this._controlActive=!0,this.domElement.getRootNode().addEventListener("keyup",this._interceptControlUp,{passive:!0,capture:!0}))}function oE(t){t.key==="Control"&&(this._controlActive=!1,this.domElement.getRootNode().removeEventListener("keyup",this._interceptControlUp,{passive:!0,capture:!0}))}function zi(t,e){return t==null||e==null?NaN:t<e?-1:t>e?1:t>=e?0:NaN}function Yh(t,e){return t==null||e==null?NaN:e<t?-1:e>t?1:e>=t?0:NaN}function Il(t){let e,n,r;t.length!==2?(e=zi,n=(a,l)=>zi(t(a),l),r=(a,l)=>t(a)-l):(e=t===zi||t===Yh?t:sE,n=t,r=t);function i(a,l,u=0,c=a.length){if(u<c){if(e(l,l)!==0)return c;do{let f=u+c>>>1;n(a[f],l)<0?u=f+1:c=f}while(u<c)}return u}function o(a,l,u=0,c=a.length){if(u<c){if(e(l,l)!==0)return c;do{let f=u+c>>>1;n(a[f],l)<=0?u=f+1:c=f}while(u<c)}return u}function s(a,l,u=0,c=a.length){let f=i(a,l,u,c-1);return f>u&&r(a[f-1],l)>-r(a[f],l)?f-1:f}return{left:i,center:s,right:o}}function sE(){return 0}function Zh(t){return t===null?NaN:+t}var Gg=Il(zi),Wg=Gg.right,aE=Gg.left,uE=Il(Zh).center,$h=Wg;function Nl(t,e){let n,r;if(e===void 0)for(let i of t)i!=null&&(n===void 0?i>=i&&(n=r=i):(n>i&&(n=i),r<i&&(r=i)));else{let i=-1;for(let o of t)(o=e(o,++i,t))!=null&&(n===void 0?o>=o&&(n=r=o):(n>o&&(n=o),r<o&&(r=o)))}return[n,r]}var lE=Math.sqrt(50),cE=Math.sqrt(10),fE=Math.sqrt(2);function Ll(t,e,n){let r=(e-t)/Math.max(0,n),i=Math.floor(Math.log10(r)),o=r/Math.pow(10,i),s=o>=lE?10:o>=cE?5:o>=fE?2:1,a,l,u;return i<0?(u=Math.pow(10,-i)/s,a=Math.round(t*u),l=Math.round(e*u),a/u<t&&++a,l/u>e&&--l,u=-u):(u=Math.pow(10,i)*s,a=Math.round(t/u),l=Math.round(e/u),a*u<t&&++a,l*u>e&&--l),l<a&&.5<=n&&n<2?Ll(t,e,n*2):[a,l,u]}function Bl(t,e,n){if(e=+e,t=+t,n=+n,!(n>0))return[];if(t===e)return[t];let r=e<t,[i,o,s]=r?Ll(e,t,n):Ll(t,e,n);if(!(o>=i))return[];let a=o-i+1,l=new Array(a);if(r)if(s<0)for(let u=0;u<a;++u)l[u]=(o-u)/-s;else for(let u=0;u<a;++u)l[u]=(o-u)*s;else if(s<0)for(let u=0;u<a;++u)l[u]=(i+u)/-s;else for(let u=0;u<a;++u)l[u]=(i+u)*s;return l}function Qs(t,e,n){return e=+e,t=+t,n=+n,Ll(t,e,n)[2]}function Jh(t,e,n){e=+e,t=+t,n=+n;let r=e<t,i=r?Qs(e,t,n):Qs(t,e,n);return(r?-1:1)*(i<0?1/-i:i)}var hE={value:()=>{}};function Xg(){for(var t=0,e=arguments.length,n={},r;t<e;++t){if(!(r=arguments[t]+"")||r in n||/[\s.]/.test(r))throw new Error("illegal type: "+r);n[r]=[]}return new Ul(n)}function Ul(t){this._=t}function dE(t,e){return t.trim().split(/^|\s+/).map(function(n){var r="",i=n.indexOf(".");if(i>=0&&(r=n.slice(i+1),n=n.slice(0,i)),n&&!e.hasOwnProperty(n))throw new Error("unknown type: "+n);return{type:n,name:r}})}Ul.prototype=Xg.prototype={constructor:Ul,on:function(t,e){var n=this._,r=dE(t+"",n),i,o=-1,s=r.length;if(arguments.length<2){for(;++o<s;)if((i=(t=r[o]).type)&&(i=pE(n[i],t.name)))return i;return}if(e!=null&&typeof e!="function")throw new Error("invalid callback: "+e);for(;++o<s;)if(i=(t=r[o]).type)n[i]=qg(n[i],t.name,e);else if(e==null)for(i in n)n[i]=qg(n[i],t.name,null);return this},copy:function(){var t={},e=this._;for(var n in e)t[n]=e[n].slice();return new Ul(t)},call:function(t,e){if((i=arguments.length-2)>0)for(var n=new Array(i),r=0,i,o;r<i;++r)n[r]=arguments[r+2];if(!this._.hasOwnProperty(t))throw new Error("unknown type: "+t);for(o=this._[t],r=0,i=o.length;r<i;++r)o[r].value.apply(e,n)},apply:function(t,e,n){if(!this._.hasOwnProperty(t))throw new Error("unknown type: "+t);for(var r=this._[t],i=0,o=r.length;i<o;++i)r[i].value.apply(e,n)}};function pE(t,e){for(var n=0,r=t.length,i;n<r;++n)if((i=t[n]).name===e)return i.value}function qg(t,e,n){for(var r=0,i=t.length;r<i;++r)if(t[r].name===e){t[r]=hE,t=t.slice(0,r).concat(t.slice(r+1));break}return n!=null&&t.push({name:e,value:n}),t}var Kh=Xg;var Ol="http://www.w3.org/1999/xhtml",Qh={svg:"http://www.w3.org/2000/svg",xhtml:Ol,xlink:"http://www.w3.org/1999/xlink",xml:"http://www.w3.org/XML/1998/namespace",xmlns:"http://www.w3.org/2000/xmlns/"};function Pr(t){var e=t+="",n=e.indexOf(":");return n>=0&&(e=t.slice(0,n))!=="xmlns"&&(t=t.slice(n+1)),Qh.hasOwnProperty(e)?{space:Qh[e],local:t}:t}function mE(t){return function(){var e=this.ownerDocument,n=this.namespaceURI;return n===Ol&&e.documentElement.namespaceURI===Ol?e.createElement(t):e.createElementNS(n,t)}}function gE(t){return function(){return this.ownerDocument.createElementNS(t.space,t.local)}}function zl(t){var e=Pr(t);return(e.local?gE:mE)(e)}function xE(){}function ki(t){return t==null?xE:function(){return this.querySelector(t)}}function Yg(t){typeof t!="function"&&(t=ki(t));for(var e=this._groups,n=e.length,r=new Array(n),i=0;i<n;++i)for(var o=e[i],s=o.length,a=r[i]=new Array(s),l,u,c=0;c<s;++c)(l=o[c])&&(u=t.call(l,l.__data__,c,o))&&("__data__"in l&&(u.__data__=l.__data__),a[c]=u);return new zt(r,this._parents)}function jh(t){return t==null?[]:Array.isArray(t)?t:Array.from(t)}function vE(){return[]}function js(t){return t==null?vE:function(){return this.querySelectorAll(t)}}function _E(t){return function(){return jh(t.apply(this,arguments))}}function Zg(t){typeof t=="function"?t=_E(t):t=js(t);for(var e=this._groups,n=e.length,r=[],i=[],o=0;o<n;++o)for(var s=e[o],a=s.length,l,u=0;u<a;++u)(l=s[u])&&(r.push(t.call(l,l.__data__,u,s)),i.push(l));return new zt(r,i)}function ea(t){return function(){return this.matches(t)}}function kl(t){return function(e){return e.matches(t)}}var yE=Array.prototype.find;function ME(t){return function(){return yE.call(this.children,t)}}function SE(){return this.firstElementChild}function $g(t){return this.select(t==null?SE:ME(typeof t=="function"?t:kl(t)))}var wE=Array.prototype.filter;function bE(){return Array.from(this.children)}function EE(t){return function(){return wE.call(this.children,t)}}function Jg(t){return this.selectAll(t==null?bE:EE(typeof t=="function"?t:kl(t)))}function Kg(t){typeof t!="function"&&(t=ea(t));for(var e=this._groups,n=e.length,r=new Array(n),i=0;i<n;++i)for(var o=e[i],s=o.length,a=r[i]=[],l,u=0;u<s;++u)(l=o[u])&&t.call(l,l.__data__,u,o)&&a.push(l);return new zt(r,this._parents)}function Vl(t){return new Array(t.length)}function Qg(){return new zt(this._enter||this._groups.map(Vl),this._parents)}function ta(t,e){this.ownerDocument=t.ownerDocument,this.namespaceURI=t.namespaceURI,this._next=null,this._parent=t,this.__data__=e}ta.prototype={constructor:ta,appendChild:function(t){return this._parent.insertBefore(t,this._next)},insertBefore:function(t,e){return this._parent.insertBefore(t,e)},querySelector:function(t){return this._parent.querySelector(t)},querySelectorAll:function(t){return this._parent.querySelectorAll(t)}};function jg(t){return function(){return t}}function DE(t,e,n,r,i,o){for(var s=0,a,l=e.length,u=o.length;s<u;++s)(a=e[s])?(a.__data__=o[s],r[s]=a):n[s]=new ta(t,o[s]);for(;s<l;++s)(a=e[s])&&(i[s]=a)}function AE(t,e,n,r,i,o,s){var a,l,u=new Map,c=e.length,f=o.length,h=new Array(c),d;for(a=0;a<c;++a)(l=e[a])&&(h[a]=d=s.call(l,l.__data__,a,e)+"",u.has(d)?i[a]=l:u.set(d,l));for(a=0;a<f;++a)d=s.call(t,o[a],a,o)+"",(l=u.get(d))?(r[a]=l,l.__data__=o[a],u.delete(d)):n[a]=new ta(t,o[a]);for(a=0;a<c;++a)(l=e[a])&&u.get(h[a])===l&&(i[a]=l)}function CE(t){return t.__data__}function e0(t,e){if(!arguments.length)return Array.from(this,CE);var n=e?AE:DE,r=this._parents,i=this._groups;typeof t!="function"&&(t=jg(t));for(var o=i.length,s=new Array(o),a=new Array(o),l=new Array(o),u=0;u<o;++u){var c=r[u],f=i[u],h=f.length,d=TE(t.call(c,c&&c.__data__,u,r)),x=d.length,p=a[u]=new Array(x),g=s[u]=new Array(x),m=l[u]=new Array(h);n(c,f,p,g,m,d,e);for(var b=0,v=0,_,M;b<x;++b)if(_=p[b]){for(b>=v&&(v=b+1);!(M=g[v])&&++v<x;);_._next=M||null}}return s=new zt(s,r),s._enter=a,s._exit=l,s}function TE(t){return typeof t=="object"&&"length"in t?t:Array.from(t)}function t0(){return new zt(this._exit||this._groups.map(Vl),this._parents)}function n0(t,e,n){var r=this.enter(),i=this,o=this.exit();return typeof t=="function"?(r=t(r),r&&(r=r.selection())):r=r.append(t+""),e!=null&&(i=e(i),i&&(i=i.selection())),n==null?o.remove():n(o),r&&i?r.merge(i).order():i}function r0(t){for(var e=t.selection?t.selection():t,n=this._groups,r=e._groups,i=n.length,o=r.length,s=Math.min(i,o),a=new Array(i),l=0;l<s;++l)for(var u=n[l],c=r[l],f=u.length,h=a[l]=new Array(f),d,x=0;x<f;++x)(d=u[x]||c[x])&&(h[x]=d);for(;l<i;++l)a[l]=n[l];return new zt(a,this._parents)}function i0(){for(var t=this._groups,e=-1,n=t.length;++e<n;)for(var r=t[e],i=r.length-1,o=r[i],s;--i>=0;)(s=r[i])&&(o&&s.compareDocumentPosition(o)^4&&o.parentNode.insertBefore(s,o),o=s);return this}function o0(t){t||(t=RE);function e(f,h){return f&&h?t(f.__data__,h.__data__):!f-!h}for(var n=this._groups,r=n.length,i=new Array(r),o=0;o<r;++o){for(var s=n[o],a=s.length,l=i[o]=new Array(a),u,c=0;c<a;++c)(u=s[c])&&(l[c]=u);l.sort(e)}return new zt(i,this._parents).order()}function RE(t,e){return t<e?-1:t>e?1:t>=e?0:NaN}function s0(){var t=arguments[0];return arguments[0]=this,t.apply(null,arguments),this}function a0(){return Array.from(this)}function u0(){for(var t=this._groups,e=0,n=t.length;e<n;++e)for(var r=t[e],i=0,o=r.length;i<o;++i){var s=r[i];if(s)return s}return null}function l0(){let t=0;for(let e of this)++t;return t}function c0(){return!this.node()}function f0(t){for(var e=this._groups,n=0,r=e.length;n<r;++n)for(var i=e[n],o=0,s=i.length,a;o<s;++o)(a=i[o])&&t.call(a,a.__data__,o,i);return this}function FE(t){return function(){this.removeAttribute(t)}}function PE(t){return function(){this.removeAttributeNS(t.space,t.local)}}function IE(t,e){return function(){this.setAttribute(t,e)}}function NE(t,e){return function(){this.setAttributeNS(t.space,t.local,e)}}function LE(t,e){return function(){var n=e.apply(this,arguments);n==null?this.removeAttribute(t):this.setAttribute(t,n)}}function BE(t,e){return function(){var n=e.apply(this,arguments);n==null?this.removeAttributeNS(t.space,t.local):this.setAttributeNS(t.space,t.local,n)}}function h0(t,e){var n=Pr(t);if(arguments.length<2){var r=this.node();return n.local?r.getAttributeNS(n.space,n.local):r.getAttribute(n)}return this.each((e==null?n.local?PE:FE:typeof e=="function"?n.local?BE:LE:n.local?NE:IE)(n,e))}function Hl(t){return t.ownerDocument&&t.ownerDocument.defaultView||t.document&&t||t.defaultView}function UE(t){return function(){this.style.removeProperty(t)}}function OE(t,e,n){return function(){this.style.setProperty(t,e,n)}}function zE(t,e,n){return function(){var r=e.apply(this,arguments);r==null?this.style.removeProperty(t):this.style.setProperty(t,r,n)}}function d0(t,e,n){return arguments.length>1?this.each((e==null?UE:typeof e=="function"?zE:OE)(t,e,n??"")):ri(this.node(),t)}function ri(t,e){return t.style.getPropertyValue(e)||Hl(t).getComputedStyle(t,null).getPropertyValue(e)}function kE(t){return function(){delete this[t]}}function VE(t,e){return function(){this[t]=e}}function HE(t,e){return function(){var n=e.apply(this,arguments);n==null?delete this[t]:this[t]=n}}function p0(t,e){return arguments.length>1?this.each((e==null?kE:typeof e=="function"?HE:VE)(t,e)):this.node()[t]}function m0(t){return t.trim().split(/^|\s+/)}function ed(t){return t.classList||new g0(t)}function g0(t){this._node=t,this._names=m0(t.getAttribute("class")||"")}g0.prototype={add:function(t){var e=this._names.indexOf(t);e<0&&(this._names.push(t),this._node.setAttribute("class",this._names.join(" ")))},remove:function(t){var e=this._names.indexOf(t);e>=0&&(this._names.splice(e,1),this._node.setAttribute("class",this._names.join(" ")))},contains:function(t){return this._names.indexOf(t)>=0}};function x0(t,e){for(var n=ed(t),r=-1,i=e.length;++r<i;)n.add(e[r])}function v0(t,e){for(var n=ed(t),r=-1,i=e.length;++r<i;)n.remove(e[r])}function GE(t){return function(){x0(this,t)}}function WE(t){return function(){v0(this,t)}}function qE(t,e){return function(){(e.apply(this,arguments)?x0:v0)(this,t)}}function _0(t,e){var n=m0(t+"");if(arguments.length<2){for(var r=ed(this.node()),i=-1,o=n.length;++i<o;)if(!r.contains(n[i]))return!1;return!0}return this.each((typeof e=="function"?qE:e?GE:WE)(n,e))}function XE(){this.textContent=""}function YE(t){return function(){this.textContent=t}}function ZE(t){return function(){var e=t.apply(this,arguments);this.textContent=e??""}}function y0(t){return arguments.length?this.each(t==null?XE:(typeof t=="function"?ZE:YE)(t)):this.node().textContent}function $E(){this.innerHTML=""}function JE(t){return function(){this.innerHTML=t}}function KE(t){return function(){var e=t.apply(this,arguments);this.innerHTML=e??""}}function M0(t){return arguments.length?this.each(t==null?$E:(typeof t=="function"?KE:JE)(t)):this.node().innerHTML}function QE(){this.nextSibling&&this.parentNode.appendChild(this)}function S0(){return this.each(QE)}function jE(){this.previousSibling&&this.parentNode.insertBefore(this,this.parentNode.firstChild)}function w0(){return this.each(jE)}function b0(t){var e=typeof t=="function"?t:zl(t);return this.select(function(){return this.appendChild(e.apply(this,arguments))})}function eD(){return null}function E0(t,e){var n=typeof t=="function"?t:zl(t),r=e==null?eD:typeof e=="function"?e:ki(e);return this.select(function(){return this.insertBefore(n.apply(this,arguments),r.apply(this,arguments)||null)})}function tD(){var t=this.parentNode;t&&t.removeChild(this)}function D0(){return this.each(tD)}function nD(){var t=this.cloneNode(!1),e=this.parentNode;return e?e.insertBefore(t,this.nextSibling):t}function rD(){var t=this.cloneNode(!0),e=this.parentNode;return e?e.insertBefore(t,this.nextSibling):t}function A0(t){return this.select(t?rD:nD)}function C0(t){return arguments.length?this.property("__data__",t):this.node().__data__}function iD(t){return function(e){t.call(this,e,this.__data__)}}function oD(t){return t.trim().split(/^|\s+/).map(function(e){var n="",r=e.indexOf(".");return r>=0&&(n=e.slice(r+1),e=e.slice(0,r)),{type:e,name:n}})}function sD(t){return function(){var e=this.__on;if(e){for(var n=0,r=-1,i=e.length,o;n<i;++n)o=e[n],(!t.type||o.type===t.type)&&o.name===t.name?this.removeEventListener(o.type,o.listener,o.options):e[++r]=o;++r?e.length=r:delete this.__on}}}function aD(t,e,n){return function(){var r=this.__on,i,o=iD(e);if(r){for(var s=0,a=r.length;s<a;++s)if((i=r[s]).type===t.type&&i.name===t.name){this.removeEventListener(i.type,i.listener,i.options),this.addEventListener(i.type,i.listener=o,i.options=n),i.value=e;return}}this.addEventListener(t.type,o,n),i={type:t.type,name:t.name,value:e,listener:o,options:n},r?r.push(i):this.__on=[i]}}function T0(t,e,n){var r=oD(t+""),i,o=r.length,s;if(arguments.length<2){var a=this.node().__on;if(a){for(var l=0,u=a.length,c;l<u;++l)for(i=0,c=a[l];i<o;++i)if((s=r[i]).type===c.type&&s.name===c.name)return c.value}return}for(a=e?aD:sD,i=0;i<o;++i)this.each(a(r[i],e,n));return this}function R0(t,e,n){var r=Hl(t),i=r.CustomEvent;typeof i=="function"?i=new i(e,n):(i=r.document.createEvent("Event"),n?(i.initEvent(e,n.bubbles,n.cancelable),i.detail=n.detail):i.initEvent(e,!1,!1)),t.dispatchEvent(i)}function uD(t,e){return function(){return R0(this,t,e)}}function lD(t,e){return function(){return R0(this,t,e.apply(this,arguments))}}function F0(t,e){return this.each((typeof e=="function"?lD:uD)(t,e))}function*P0(){for(var t=this._groups,e=0,n=t.length;e<n;++e)for(var r=t[e],i=0,o=r.length,s;i<o;++i)(s=r[i])&&(yield s)}var cD=[null];function zt(t,e){this._groups=t,this._parents=e}function I0(){return new zt([[document.documentElement]],cD)}function fD(){return this}zt.prototype=I0.prototype={constructor:zt,select:Yg,selectAll:Zg,selectChild:$g,selectChildren:Jg,filter:Kg,data:e0,enter:Qg,exit:t0,join:n0,merge:r0,selection:fD,order:i0,sort:o0,call:s0,nodes:a0,node:u0,size:l0,empty:c0,each:f0,attr:h0,style:d0,property:p0,classed:_0,text:y0,html:M0,raise:S0,lower:w0,append:b0,insert:E0,remove:D0,clone:A0,datum:C0,on:T0,dispatch:F0,[Symbol.iterator]:P0};var Ir=I0;function Gl(t,e,n){t.prototype=e.prototype=n,n.constructor=t}function td(t,e){var n=Object.create(t.prototype);for(var r in e)n[r]=e[r];return n}function ia(){}var na=.7,Xl=1/na,Go="\\s*([+-]?\\d+)\\s*",ra="\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)\\s*",pr="\\s*([+-]?(?:\\d*\\.)?\\d+(?:[eE][+-]?\\d+)?)%\\s*",hD=/^#([0-9a-f]{3,8})$/,dD=new RegExp(`^rgb\\(${Go},${Go},${Go}\\)$`),pD=new RegExp(`^rgb\\(${pr},${pr},${pr}\\)$`),mD=new RegExp(`^rgba\\(${Go},${Go},${Go},${ra}\\)$`),gD=new RegExp(`^rgba\\(${pr},${pr},${pr},${ra}\\)$`),xD=new RegExp(`^hsl\\(${ra},${pr},${pr}\\)$`),vD=new RegExp(`^hsla\\(${ra},${pr},${pr},${ra}\\)$`),N0={aliceblue:15792383,antiquewhite:16444375,aqua:65535,aquamarine:8388564,azure:15794175,beige:16119260,bisque:16770244,black:0,blanchedalmond:16772045,blue:255,blueviolet:9055202,brown:10824234,burlywood:14596231,cadetblue:6266528,chartreuse:8388352,chocolate:13789470,coral:16744272,cornflowerblue:6591981,cornsilk:16775388,crimson:14423100,cyan:65535,darkblue:139,darkcyan:35723,darkgoldenrod:12092939,darkgray:11119017,darkgreen:25600,darkgrey:11119017,darkkhaki:12433259,darkmagenta:9109643,darkolivegreen:5597999,darkorange:16747520,darkorchid:10040012,darkred:9109504,darksalmon:15308410,darkseagreen:9419919,darkslateblue:4734347,darkslategray:3100495,darkslategrey:3100495,darkturquoise:52945,darkviolet:9699539,deeppink:16716947,deepskyblue:49151,dimgray:6908265,dimgrey:6908265,dodgerblue:2003199,firebrick:11674146,floralwhite:16775920,forestgreen:2263842,fuchsia:16711935,gainsboro:14474460,ghostwhite:16316671,gold:16766720,goldenrod:14329120,gray:8421504,green:32768,greenyellow:11403055,grey:8421504,honeydew:15794160,hotpink:16738740,indianred:13458524,indigo:4915330,ivory:16777200,khaki:15787660,lavender:15132410,lavenderblush:16773365,lawngreen:8190976,lemonchiffon:16775885,lightblue:11393254,lightcoral:15761536,lightcyan:14745599,lightgoldenrodyellow:16448210,lightgray:13882323,lightgreen:9498256,lightgrey:13882323,lightpink:16758465,lightsalmon:16752762,lightseagreen:2142890,lightskyblue:8900346,lightslategray:7833753,lightslategrey:7833753,lightsteelblue:11584734,lightyellow:16777184,lime:65280,limegreen:3329330,linen:16445670,magenta:16711935,maroon:8388608,mediumaquamarine:6737322,mediumblue:205,mediumorchid:12211667,mediumpurple:9662683,mediumseagreen:3978097,mediumslateblue:8087790,mediumspringgreen:64154,mediumturquoise:4772300,mediumvioletred:13047173,midnightblue:1644912,mintcream:16121850,mistyrose:16770273,moccasin:16770229,navajowhite:16768685,navy:128,oldlace:16643558,olive:8421376,olivedrab:7048739,orange:16753920,orangered:16729344,orchid:14315734,palegoldenrod:15657130,palegreen:10025880,paleturquoise:11529966,palevioletred:14381203,papayawhip:16773077,peachpuff:16767673,peru:13468991,pink:16761035,plum:14524637,powderblue:11591910,purple:8388736,rebeccapurple:6697881,red:16711680,rosybrown:12357519,royalblue:4286945,saddlebrown:9127187,salmon:16416882,sandybrown:16032864,seagreen:3050327,seashell:16774638,sienna:10506797,silver:12632256,skyblue:8900331,slateblue:6970061,slategray:7372944,slategrey:7372944,snow:16775930,springgreen:65407,steelblue:4620980,tan:13808780,teal:32896,thistle:14204888,tomato:16737095,turquoise:4251856,violet:15631086,wheat:16113331,white:16777215,whitesmoke:16119285,yellow:16776960,yellowgreen:10145074};Gl(ia,nr,{copy(t){return Object.assign(new this.constructor,this,t)},displayable(){return this.rgb().displayable()},hex:L0,formatHex:L0,formatHex8:_D,formatHsl:yD,formatRgb:B0,toString:B0});function L0(){return this.rgb().formatHex()}function _D(){return this.rgb().formatHex8()}function yD(){return H0(this).formatHsl()}function B0(){return this.rgb().formatRgb()}function nr(t){var e,n;return t=(t+"").trim().toLowerCase(),(e=hD.exec(t))?(n=e[1].length,e=parseInt(e[1],16),n===6?U0(e):n===3?new xn(e>>8&15|e>>4&240,e>>4&15|e&240,(e&15)<<4|e&15,1):n===8?Wl(e>>24&255,e>>16&255,e>>8&255,(e&255)/255):n===4?Wl(e>>12&15|e>>8&240,e>>8&15|e>>4&240,e>>4&15|e&240,((e&15)<<4|e&15)/255):null):(e=dD.exec(t))?new xn(e[1],e[2],e[3],1):(e=pD.exec(t))?new xn(e[1]*255/100,e[2]*255/100,e[3]*255/100,1):(e=mD.exec(t))?Wl(e[1],e[2],e[3],e[4]):(e=gD.exec(t))?Wl(e[1]*255/100,e[2]*255/100,e[3]*255/100,e[4]):(e=xD.exec(t))?k0(e[1],e[2]/100,e[3]/100,1):(e=vD.exec(t))?k0(e[1],e[2]/100,e[3]/100,e[4]):N0.hasOwnProperty(t)?U0(N0[t]):t==="transparent"?new xn(NaN,NaN,NaN,0):null}function U0(t){return new xn(t>>16&255,t>>8&255,t&255,1)}function Wl(t,e,n,r){return r<=0&&(t=e=n=NaN),new xn(t,e,n,r)}function MD(t){return t instanceof ia||(t=nr(t)),t?(t=t.rgb(),new xn(t.r,t.g,t.b,t.opacity)):new xn}function Wo(t,e,n,r){return arguments.length===1?MD(t):new xn(t,e,n,r??1)}function xn(t,e,n,r){this.r=+t,this.g=+e,this.b=+n,this.opacity=+r}Gl(xn,Wo,td(ia,{brighter(t){return t=t==null?Xl:Math.pow(Xl,t),new xn(this.r*t,this.g*t,this.b*t,this.opacity)},darker(t){return t=t==null?na:Math.pow(na,t),new xn(this.r*t,this.g*t,this.b*t,this.opacity)},rgb(){return this},clamp(){return new xn(Hi(this.r),Hi(this.g),Hi(this.b),Yl(this.opacity))},displayable(){return-.5<=this.r&&this.r<255.5&&-.5<=this.g&&this.g<255.5&&-.5<=this.b&&this.b<255.5&&0<=this.opacity&&this.opacity<=1},hex:O0,formatHex:O0,formatHex8:SD,formatRgb:z0,toString:z0}));function O0(){return`#${Vi(this.r)}${Vi(this.g)}${Vi(this.b)}`}function SD(){return`#${Vi(this.r)}${Vi(this.g)}${Vi(this.b)}${Vi((isNaN(this.opacity)?1:this.opacity)*255)}`}function z0(){let t=Yl(this.opacity);return`${t===1?"rgb(":"rgba("}${Hi(this.r)}, ${Hi(this.g)}, ${Hi(this.b)}${t===1?")":`, ${t})`}`}function Yl(t){return isNaN(t)?1:Math.max(0,Math.min(1,t))}function Hi(t){return Math.max(0,Math.min(255,Math.round(t)||0))}function Vi(t){return t=Hi(t),(t<16?"0":"")+t.toString(16)}function k0(t,e,n,r){return r<=0?t=e=n=NaN:n<=0||n>=1?t=e=NaN:e<=0&&(t=NaN),new tr(t,e,n,r)}function H0(t){if(t instanceof tr)return new tr(t.h,t.s,t.l,t.opacity);if(t instanceof ia||(t=nr(t)),!t)return new tr;if(t instanceof tr)return t;t=t.rgb();var e=t.r/255,n=t.g/255,r=t.b/255,i=Math.min(e,n,r),o=Math.max(e,n,r),s=NaN,a=o-i,l=(o+i)/2;return a?(e===o?s=(n-r)/a+(n<r)*6:n===o?s=(r-e)/a+2:s=(e-n)/a+4,a/=l<.5?o+i:2-o-i,s*=60):a=l>0&&l<1?0:s,new tr(s,a,l,t.opacity)}function G0(t,e,n,r){return arguments.length===1?H0(t):new tr(t,e,n,r??1)}function tr(t,e,n,r){this.h=+t,this.s=+e,this.l=+n,this.opacity=+r}Gl(tr,G0,td(ia,{brighter(t){return t=t==null?Xl:Math.pow(Xl,t),new tr(this.h,this.s,this.l*t,this.opacity)},darker(t){return t=t==null?na:Math.pow(na,t),new tr(this.h,this.s,this.l*t,this.opacity)},rgb(){var t=this.h%360+(this.h<0)*360,e=isNaN(t)||isNaN(this.s)?0:this.s,n=this.l,r=n+(n<.5?n:1-n)*e,i=2*n-r;return new xn(nd(t>=240?t-240:t+120,i,r),nd(t,i,r),nd(t<120?t+240:t-120,i,r),this.opacity)},clamp(){return new tr(V0(this.h),ql(this.s),ql(this.l),Yl(this.opacity))},displayable(){return(0<=this.s&&this.s<=1||isNaN(this.s))&&0<=this.l&&this.l<=1&&0<=this.opacity&&this.opacity<=1},formatHsl(){let t=Yl(this.opacity);return`${t===1?"hsl(":"hsla("}${V0(this.h)}, ${ql(this.s)*100}%, ${ql(this.l)*100}%${t===1?")":`, ${t})`}`}}));function V0(t){return t=(t||0)%360,t<0?t+360:t}function ql(t){return Math.max(0,Math.min(1,t||0))}function nd(t,e,n){return(t<60?e+(n-e)*t/60:t<180?n:t<240?e+(n-e)*(240-t)/60:e)*255}function rd(t,e,n,r,i){var o=t*t,s=o*t;return((1-3*t+3*o-s)*e+(4-6*o+3*s)*n+(1+3*t+3*o-3*s)*r+s*i)/6}function W0(t){var e=t.length-1;return function(n){var r=n<=0?n=0:n>=1?(n=1,e-1):Math.floor(n*e),i=t[r],o=t[r+1],s=r>0?t[r-1]:2*i-o,a=r<e-1?t[r+2]:2*o-i;return rd((n-r/e)*e,s,i,o,a)}}function q0(t){var e=t.length;return function(n){var r=Math.floor(((n%=1)<0?++n:n)*e),i=t[(r+e-1)%e],o=t[r%e],s=t[(r+1)%e],a=t[(r+2)%e];return rd((n-r/e)*e,i,o,s,a)}}var oa=t=>()=>t;function wD(t,e){return function(n){return t+n*e}}function bD(t,e,n){return t=Math.pow(t,n),e=Math.pow(e,n)-t,n=1/n,function(r){return Math.pow(t+r*e,n)}}function X0(t){return(t=+t)==1?Zl:function(e,n){return n-e?bD(e,n,t):oa(isNaN(e)?n:e)}}function Zl(t,e){var n=e-t;return n?wD(t,n):oa(isNaN(t)?e:t)}var Gi=(function t(e){var n=X0(e);function r(i,o){var s=n((i=Wo(i)).r,(o=Wo(o)).r),a=n(i.g,o.g),l=n(i.b,o.b),u=Zl(i.opacity,o.opacity);return function(c){return i.r=s(c),i.g=a(c),i.b=l(c),i.opacity=u(c),i+""}}return r.gamma=t,r})(1);function Y0(t){return function(e){var n=e.length,r=new Array(n),i=new Array(n),o=new Array(n),s,a;for(s=0;s<n;++s)a=Wo(e[s]),r[s]=a.r||0,i[s]=a.g||0,o[s]=a.b||0;return r=t(r),i=t(i),o=t(o),a.opacity=1,function(l){return a.r=r(l),a.g=i(l),a.b=o(l),a+""}}}var ED=Y0(W0),DD=Y0(q0);function Z0(t,e){e||(e=[]);var n=t?Math.min(e.length,t.length):0,r=e.slice(),i;return function(o){for(i=0;i<n;++i)r[i]=t[i]*(1-o)+e[i]*o;return r}}function $0(t){return ArrayBuffer.isView(t)&&!(t instanceof DataView)}function J0(t,e){var n=e?e.length:0,r=t?Math.min(n,t.length):0,i=new Array(r),o=new Array(n),s;for(s=0;s<r;++s)i[s]=Wi(t[s],e[s]);for(;s<n;++s)o[s]=e[s];return function(a){for(s=0;s<r;++s)o[s]=i[s](a);return o}}function K0(t,e){var n=new Date;return t=+t,e=+e,function(r){return n.setTime(t*(1-r)+e*r),n}}function $t(t,e){return t=+t,e=+e,function(n){return t*(1-n)+e*n}}function Q0(t,e){var n={},r={},i;(t===null||typeof t!="object")&&(t={}),(e===null||typeof e!="object")&&(e={});for(i in e)i in t?n[i]=Wi(t[i],e[i]):r[i]=e[i];return function(o){for(i in n)r[i]=n[i](o);return r}}var od=/[-+]?(?:\d+\.?\d*|\.?\d+)(?:[eE][-+]?\d+)?/g,id=new RegExp(od.source,"g");function AD(t){return function(){return t}}function CD(t){return function(e){return t(e)+""}}function sa(t,e){var n=od.lastIndex=id.lastIndex=0,r,i,o,s=-1,a=[],l=[];for(t=t+"",e=e+"";(r=od.exec(t))&&(i=id.exec(e));)(o=i.index)>n&&(o=e.slice(n,o),a[s]?a[s]+=o:a[++s]=o),(r=r[0])===(i=i[0])?a[s]?a[s]+=i:a[++s]=i:(a[++s]=null,l.push({i:s,x:$t(r,i)})),n=id.lastIndex;return n<e.length&&(o=e.slice(n),a[s]?a[s]+=o:a[++s]=o),a.length<2?l[0]?CD(l[0].x):AD(e):(e=l.length,function(u){for(var c=0,f;c<e;++c)a[(f=l[c]).i]=f.x(u);return a.join("")})}function Wi(t,e){var n=typeof e,r;return e==null||n==="boolean"?oa(e):(n==="number"?$t:n==="string"?(r=nr(e))?(e=r,Gi):sa:e instanceof nr?Gi:e instanceof Date?K0:$0(e)?Z0:Array.isArray(e)?J0:typeof e.valueOf!="function"&&typeof e.toString!="function"||isNaN(e)?Q0:$t)(t,e)}function sd(t,e){return t=+t,e=+e,function(n){return Math.round(t*(1-n)+e*n)}}var j0=180/Math.PI,$l={translateX:0,translateY:0,rotate:0,skewX:0,scaleX:1,scaleY:1};function ad(t,e,n,r,i,o){var s,a,l;return(s=Math.sqrt(t*t+e*e))&&(t/=s,e/=s),(l=t*n+e*r)&&(n-=t*l,r-=e*l),(a=Math.sqrt(n*n+r*r))&&(n/=a,r/=a,l/=a),t*r<e*n&&(t=-t,e=-e,l=-l,s=-s),{translateX:i,translateY:o,rotate:Math.atan2(e,t)*j0,skewX:Math.atan(l)*j0,scaleX:s,scaleY:a}}var Jl;function ex(t){let e=new(typeof DOMMatrix=="function"?DOMMatrix:WebKitCSSMatrix)(t+"");return e.isIdentity?$l:ad(e.a,e.b,e.c,e.d,e.e,e.f)}function tx(t){return t==null?$l:(Jl||(Jl=document.createElementNS("http://www.w3.org/2000/svg","g")),Jl.setAttribute("transform",t),(t=Jl.transform.baseVal.consolidate())?(t=t.matrix,ad(t.a,t.b,t.c,t.d,t.e,t.f)):$l)}function nx(t,e,n,r){function i(u){return u.length?u.pop()+" ":""}function o(u,c,f,h,d,x){if(u!==f||c!==h){var p=d.push("translate(",null,e,null,n);x.push({i:p-4,x:$t(u,f)},{i:p-2,x:$t(c,h)})}else(f||h)&&d.push("translate("+f+e+h+n)}function s(u,c,f,h){u!==c?(u-c>180?c+=360:c-u>180&&(u+=360),h.push({i:f.push(i(f)+"rotate(",null,r)-2,x:$t(u,c)})):c&&f.push(i(f)+"rotate("+c+r)}function a(u,c,f,h){u!==c?h.push({i:f.push(i(f)+"skewX(",null,r)-2,x:$t(u,c)}):c&&f.push(i(f)+"skewX("+c+r)}function l(u,c,f,h,d,x){if(u!==f||c!==h){var p=d.push(i(d)+"scale(",null,",",null,")");x.push({i:p-4,x:$t(u,f)},{i:p-2,x:$t(c,h)})}else(f!==1||h!==1)&&d.push(i(d)+"scale("+f+","+h+")")}return function(u,c){var f=[],h=[];return u=t(u),c=t(c),o(u.translateX,u.translateY,c.translateX,c.translateY,f,h),s(u.rotate,c.rotate,f,h),a(u.skewX,c.skewX,f,h),l(u.scaleX,u.scaleY,c.scaleX,c.scaleY,f,h),u=c=null,function(d){for(var x=-1,p=h.length,g;++x<p;)f[(g=h[x]).i]=g.x(d);return f.join("")}}}var ud=nx(ex,"px, ","px)","deg)"),ld=nx(tx,", ",")",")");var qo=0,ua=0,aa=0,ix=1e3,Kl,la,Ql=0,qi=0,jl=0,ca=typeof performance=="object"&&performance.now?performance:Date,ox=typeof window=="object"&&window.requestAnimationFrame?window.requestAnimationFrame.bind(window):function(t){setTimeout(t,17)};function ha(){return qi||(ox(TD),qi=ca.now()+jl)}function TD(){qi=0}function fa(){this._call=this._time=this._next=null}fa.prototype=ec.prototype={constructor:fa,restart:function(t,e,n){if(typeof t!="function")throw new TypeError("callback is not a function");n=(n==null?ha():+n)+(e==null?0:+e),!this._next&&la!==this&&(la?la._next=this:Kl=this,la=this),this._call=t,this._time=n,cd()},stop:function(){this._call&&(this._call=null,this._time=1/0,cd())}};function ec(t,e,n){var r=new fa;return r.restart(t,e,n),r}function sx(){ha(),++qo;for(var t=Kl,e;t;)(e=qi-t._time)>=0&&t._call.call(void 0,e),t=t._next;--qo}function rx(){qi=(Ql=ca.now())+jl,qo=ua=0;try{sx()}finally{qo=0,FD(),qi=0}}function RD(){var t=ca.now(),e=t-Ql;e>ix&&(jl-=e,Ql=t)}function FD(){for(var t,e=Kl,n,r=1/0;e;)e._call?(r>e._time&&(r=e._time),t=e,e=e._next):(n=e._next,e._next=null,e=t?t._next=n:Kl=n);la=t,cd(r)}function cd(t){if(!qo){ua&&(ua=clearTimeout(ua));var e=t-qi;e>24?(t<1/0&&(ua=setTimeout(rx,t-ca.now()-jl)),aa&&(aa=clearInterval(aa))):(aa||(Ql=ca.now(),aa=setInterval(RD,ix)),qo=1,ox(rx))}}function tc(t,e,n){var r=new fa;return e=e==null?0:+e,r.restart(i=>{r.stop(),t(i+e)},e,n),r}var PD=Kh("start","end","cancel","interrupt"),ID=[],lx=0,ax=1,rc=2,nc=3,ux=4,ic=5,da=6;function ii(t,e,n,r,i,o){var s=t.__transition;if(!s)t.__transition={};else if(n in s)return;ND(t,n,{name:e,index:r,group:i,on:PD,tween:ID,time:o.time,delay:o.delay,duration:o.duration,ease:o.ease,timer:null,state:lx})}function pa(t,e){var n=kt(t,e);if(n.state>lx)throw new Error("too late; already scheduled");return n}function Jt(t,e){var n=kt(t,e);if(n.state>nc)throw new Error("too late; already running");return n}function kt(t,e){var n=t.__transition;if(!n||!(n=n[e]))throw new Error("transition not found");return n}function ND(t,e,n){var r=t.__transition,i;r[e]=n,n.timer=ec(o,0,n.time);function o(u){n.state=ax,n.timer.restart(s,n.delay,n.time),n.delay<=u&&s(u-n.delay)}function s(u){var c,f,h,d;if(n.state!==ax)return l();for(c in r)if(d=r[c],d.name===n.name){if(d.state===nc)return tc(s);d.state===ux?(d.state=da,d.timer.stop(),d.on.call("interrupt",t,t.__data__,d.index,d.group),delete r[c]):+c<e&&(d.state=da,d.timer.stop(),d.on.call("cancel",t,t.__data__,d.index,d.group),delete r[c])}if(tc(function(){n.state===nc&&(n.state=ux,n.timer.restart(a,n.delay,n.time),a(u))}),n.state=rc,n.on.call("start",t,t.__data__,n.index,n.group),n.state===rc){for(n.state=nc,i=new Array(h=n.tween.length),c=0,f=-1;c<h;++c)(d=n.tween[c].value.call(t,t.__data__,n.index,n.group))&&(i[++f]=d);i.length=f+1}}function a(u){for(var c=u<n.duration?n.ease.call(null,u/n.duration):(n.timer.restart(l),n.state=ic,1),f=-1,h=i.length;++f<h;)i[f].call(t,c);n.state===ic&&(n.on.call("end",t,t.__data__,n.index,n.group),l())}function l(){n.state=da,n.timer.stop(),delete r[e];for(var u in r)return;delete t.__transition}}function oc(t,e){var n=t.__transition,r,i,o=!0,s;if(n){e=e==null?null:e+"";for(s in n){if((r=n[s]).name!==e){o=!1;continue}i=r.state>rc&&r.state<ic,r.state=da,r.timer.stop(),r.on.call(i?"interrupt":"cancel",t,t.__data__,r.index,r.group),delete n[s]}o&&delete t.__transition}}function cx(t){return this.each(function(){oc(this,t)})}function LD(t,e){var n,r;return function(){var i=Jt(this,t),o=i.tween;if(o!==n){r=n=o;for(var s=0,a=r.length;s<a;++s)if(r[s].name===e){r=r.slice(),r.splice(s,1);break}}i.tween=r}}function BD(t,e,n){var r,i;if(typeof n!="function")throw new Error;return function(){var o=Jt(this,t),s=o.tween;if(s!==r){i=(r=s).slice();for(var a={name:e,value:n},l=0,u=i.length;l<u;++l)if(i[l].name===e){i[l]=a;break}l===u&&i.push(a)}o.tween=i}}function fx(t,e){var n=this._id;if(t+="",arguments.length<2){for(var r=kt(this.node(),n).tween,i=0,o=r.length,s;i<o;++i)if((s=r[i]).name===t)return s.value;return null}return this.each((e==null?LD:BD)(n,t,e))}function Xo(t,e,n){var r=t._id;return t.each(function(){var i=Jt(this,r);(i.value||(i.value={}))[e]=n.apply(this,arguments)}),function(i){return kt(i,r).value[e]}}function sc(t,e){var n;return(typeof e=="number"?$t:e instanceof nr?Gi:(n=nr(e))?(e=n,Gi):sa)(t,e)}function UD(t){return function(){this.removeAttribute(t)}}function OD(t){return function(){this.removeAttributeNS(t.space,t.local)}}function zD(t,e,n){var r,i=n+"",o;return function(){var s=this.getAttribute(t);return s===i?null:s===r?o:o=e(r=s,n)}}function kD(t,e,n){var r,i=n+"",o;return function(){var s=this.getAttributeNS(t.space,t.local);return s===i?null:s===r?o:o=e(r=s,n)}}function VD(t,e,n){var r,i,o;return function(){var s,a=n(this),l;return a==null?void this.removeAttribute(t):(s=this.getAttribute(t),l=a+"",s===l?null:s===r&&l===i?o:(i=l,o=e(r=s,a)))}}function HD(t,e,n){var r,i,o;return function(){var s,a=n(this),l;return a==null?void this.removeAttributeNS(t.space,t.local):(s=this.getAttributeNS(t.space,t.local),l=a+"",s===l?null:s===r&&l===i?o:(i=l,o=e(r=s,a)))}}function hx(t,e){var n=Pr(t),r=n==="transform"?ld:sc;return this.attrTween(t,typeof e=="function"?(n.local?HD:VD)(n,r,Xo(this,"attr."+t,e)):e==null?(n.local?OD:UD)(n):(n.local?kD:zD)(n,r,e))}function GD(t,e){return function(n){this.setAttribute(t,e.call(this,n))}}function WD(t,e){return function(n){this.setAttributeNS(t.space,t.local,e.call(this,n))}}function qD(t,e){var n,r;function i(){var o=e.apply(this,arguments);return o!==r&&(n=(r=o)&&WD(t,o)),n}return i._value=e,i}function XD(t,e){var n,r;function i(){var o=e.apply(this,arguments);return o!==r&&(n=(r=o)&&GD(t,o)),n}return i._value=e,i}function dx(t,e){var n="attr."+t;if(arguments.length<2)return(n=this.tween(n))&&n._value;if(e==null)return this.tween(n,null);if(typeof e!="function")throw new Error;var r=Pr(t);return this.tween(n,(r.local?qD:XD)(r,e))}function YD(t,e){return function(){pa(this,t).delay=+e.apply(this,arguments)}}function ZD(t,e){return e=+e,function(){pa(this,t).delay=e}}function px(t){var e=this._id;return arguments.length?this.each((typeof t=="function"?YD:ZD)(e,t)):kt(this.node(),e).delay}function $D(t,e){return function(){Jt(this,t).duration=+e.apply(this,arguments)}}function JD(t,e){return e=+e,function(){Jt(this,t).duration=e}}function mx(t){var e=this._id;return arguments.length?this.each((typeof t=="function"?$D:JD)(e,t)):kt(this.node(),e).duration}function KD(t,e){if(typeof e!="function")throw new Error;return function(){Jt(this,t).ease=e}}function gx(t){var e=this._id;return arguments.length?this.each(KD(e,t)):kt(this.node(),e).ease}function QD(t,e){return function(){var n=e.apply(this,arguments);if(typeof n!="function")throw new Error;Jt(this,t).ease=n}}function xx(t){if(typeof t!="function")throw new Error;return this.each(QD(this._id,t))}function vx(t){typeof t!="function"&&(t=ea(t));for(var e=this._groups,n=e.length,r=new Array(n),i=0;i<n;++i)for(var o=e[i],s=o.length,a=r[i]=[],l,u=0;u<s;++u)(l=o[u])&&t.call(l,l.__data__,u,o)&&a.push(l);return new hn(r,this._parents,this._name,this._id)}function _x(t){if(t._id!==this._id)throw new Error;for(var e=this._groups,n=t._groups,r=e.length,i=n.length,o=Math.min(r,i),s=new Array(r),a=0;a<o;++a)for(var l=e[a],u=n[a],c=l.length,f=s[a]=new Array(c),h,d=0;d<c;++d)(h=l[d]||u[d])&&(f[d]=h);for(;a<r;++a)s[a]=e[a];return new hn(s,this._parents,this._name,this._id)}function jD(t){return(t+"").trim().split(/^|\s+/).every(function(e){var n=e.indexOf(".");return n>=0&&(e=e.slice(0,n)),!e||e==="start"})}function eA(t,e,n){var r,i,o=jD(e)?pa:Jt;return function(){var s=o(this,t),a=s.on;a!==r&&(i=(r=a).copy()).on(e,n),s.on=i}}function yx(t,e){var n=this._id;return arguments.length<2?kt(this.node(),n).on.on(t):this.each(eA(n,t,e))}function tA(t){return function(){var e=this.parentNode;for(var n in this.__transition)if(+n!==t)return;e&&e.removeChild(this)}}function Mx(){return this.on("end.remove",tA(this._id))}function Sx(t){var e=this._name,n=this._id;typeof t!="function"&&(t=ki(t));for(var r=this._groups,i=r.length,o=new Array(i),s=0;s<i;++s)for(var a=r[s],l=a.length,u=o[s]=new Array(l),c,f,h=0;h<l;++h)(c=a[h])&&(f=t.call(c,c.__data__,h,a))&&("__data__"in c&&(f.__data__=c.__data__),u[h]=f,ii(u[h],e,n,h,u,kt(c,n)));return new hn(o,this._parents,e,n)}function wx(t){var e=this._name,n=this._id;typeof t!="function"&&(t=js(t));for(var r=this._groups,i=r.length,o=[],s=[],a=0;a<i;++a)for(var l=r[a],u=l.length,c,f=0;f<u;++f)if(c=l[f]){for(var h=t.call(c,c.__data__,f,l),d,x=kt(c,n),p=0,g=h.length;p<g;++p)(d=h[p])&&ii(d,e,n,p,h,x);o.push(h),s.push(c)}return new hn(o,s,e,n)}var nA=Ir.prototype.constructor;function bx(){return new nA(this._groups,this._parents)}function rA(t,e){var n,r,i;return function(){var o=ri(this,t),s=(this.style.removeProperty(t),ri(this,t));return o===s?null:o===n&&s===r?i:i=e(n=o,r=s)}}function Ex(t){return function(){this.style.removeProperty(t)}}function iA(t,e,n){var r,i=n+"",o;return function(){var s=ri(this,t);return s===i?null:s===r?o:o=e(r=s,n)}}function oA(t,e,n){var r,i,o;return function(){var s=ri(this,t),a=n(this),l=a+"";return a==null&&(l=a=(this.style.removeProperty(t),ri(this,t))),s===l?null:s===r&&l===i?o:(i=l,o=e(r=s,a))}}function sA(t,e){var n,r,i,o="style."+e,s="end."+o,a;return function(){var l=Jt(this,t),u=l.on,c=l.value[o]==null?a||(a=Ex(e)):void 0;(u!==n||i!==c)&&(r=(n=u).copy()).on(s,i=c),l.on=r}}function Dx(t,e,n){var r=(t+="")=="transform"?ud:sc;return e==null?this.styleTween(t,rA(t,r)).on("end.style."+t,Ex(t)):typeof e=="function"?this.styleTween(t,oA(t,r,Xo(this,"style."+t,e))).each(sA(this._id,t)):this.styleTween(t,iA(t,r,e),n).on("end.style."+t,null)}function aA(t,e,n){return function(r){this.style.setProperty(t,e.call(this,r),n)}}function uA(t,e,n){var r,i;function o(){var s=e.apply(this,arguments);return s!==i&&(r=(i=s)&&aA(t,s,n)),r}return o._value=e,o}function Ax(t,e,n){var r="style."+(t+="");if(arguments.length<2)return(r=this.tween(r))&&r._value;if(e==null)return this.tween(r,null);if(typeof e!="function")throw new Error;return this.tween(r,uA(t,e,n??""))}function lA(t){return function(){this.textContent=t}}function cA(t){return function(){var e=t(this);this.textContent=e??""}}function Cx(t){return this.tween("text",typeof t=="function"?cA(Xo(this,"text",t)):lA(t==null?"":t+""))}function fA(t){return function(e){this.textContent=t.call(this,e)}}function hA(t){var e,n;function r(){var i=t.apply(this,arguments);return i!==n&&(e=(n=i)&&fA(i)),e}return r._value=t,r}function Tx(t){var e="text";if(arguments.length<1)return(e=this.tween(e))&&e._value;if(t==null)return this.tween(e,null);if(typeof t!="function")throw new Error;return this.tween(e,hA(t))}function Rx(){for(var t=this._name,e=this._id,n=ac(),r=this._groups,i=r.length,o=0;o<i;++o)for(var s=r[o],a=s.length,l,u=0;u<a;++u)if(l=s[u]){var c=kt(l,e);ii(l,t,n,u,s,{time:c.time+c.delay+c.duration,delay:0,duration:c.duration,ease:c.ease})}return new hn(r,this._parents,t,n)}function Fx(){var t,e,n=this,r=n._id,i=n.size();return new Promise(function(o,s){var a={value:s},l={value:function(){--i===0&&o()}};n.each(function(){var u=Jt(this,r),c=u.on;c!==t&&(e=(t=c).copy(),e._.cancel.push(a),e._.interrupt.push(a),e._.end.push(l)),u.on=e}),i===0&&o()})}var dA=0;function hn(t,e,n,r){this._groups=t,this._parents=e,this._name=n,this._id=r}function Px(t){return Ir().transition(t)}function ac(){return++dA}var Nr=Ir.prototype;hn.prototype=Px.prototype={constructor:hn,select:Sx,selectAll:wx,selectChild:Nr.selectChild,selectChildren:Nr.selectChildren,filter:vx,merge:_x,selection:bx,transition:Rx,call:Nr.call,nodes:Nr.nodes,node:Nr.node,size:Nr.size,empty:Nr.empty,each:Nr.each,on:yx,attr:hx,attrTween:dx,style:Dx,styleTween:Ax,text:Cx,textTween:Tx,remove:Mx,tween:fx,delay:px,duration:mx,ease:gx,easeVarying:xx,end:Fx,[Symbol.iterator]:Nr[Symbol.iterator]};function uc(t){return((t*=2)<=1?t*t*t:(t-=2)*t*t+2)/2}var pA={time:null,delay:0,duration:250,ease:uc};function mA(t,e){for(var n;!(n=t.__transition)||!(n=n[e]);)if(!(t=t.parentNode))throw new Error(`transition ${e} not found`);return n}function Ix(t){var e,n;t instanceof hn?(e=t._id,t=t._name):(e=ac(),(n=pA).time=ha(),t=t==null?null:t+"");for(var r=this._groups,i=r.length,o=0;o<i;++o)for(var s=r[o],a=s.length,l,u=0;u<a;++u)(l=s[u])&&ii(l,t,e,u,s,n||mA(l,e));return new hn(r,this._parents,t,e)}Ir.prototype.interrupt=cx;Ir.prototype.transition=Ix;var{abs:dU,max:pU,min:mU}=Math;function Nx(t){return[+t[0],+t[1]]}function gA(t){return[Nx(t[0]),Nx(t[1])]}var gU={name:"x",handles:["w","e"].map(fd),input:function(t,e){return t==null?null:[[+t[0],e[0][1]],[+t[1],e[1][1]]]},output:function(t){return t&&[t[0][0],t[1][0]]}},xU={name:"y",handles:["n","s"].map(fd),input:function(t,e){return t==null?null:[[e[0][0],+t[0]],[e[1][0],+t[1]]]},output:function(t){return t&&[t[0][1],t[1][1]]}},vU={name:"xy",handles:["n","w","e","s","nw","ne","sw","se"].map(fd),input:function(t){return t==null?null:gA(t)},output:function(t){return t}};function fd(t){return{type:t}}var hd=Math.PI,dd=2*hd,Xi=1e-6,xA=dd-Xi;function Lx(t){this._+=t[0];for(let e=1,n=t.length;e<n;++e)this._+=arguments[e]+t[e]}function vA(t){let e=Math.floor(t);if(!(e>=0))throw new Error(`invalid digits: ${t}`);if(e>15)return Lx;let n=10**e;return function(r){this._+=r[0];for(let i=1,o=r.length;i<o;++i)this._+=Math.round(arguments[i]*n)/n+r[i]}}var Yi=class{constructor(e){this._x0=this._y0=this._x1=this._y1=null,this._="",this._append=e==null?Lx:vA(e)}moveTo(e,n){this._append`M${this._x0=this._x1=+e},${this._y0=this._y1=+n}`}closePath(){this._x1!==null&&(this._x1=this._x0,this._y1=this._y0,this._append`Z`)}lineTo(e,n){this._append`L${this._x1=+e},${this._y1=+n}`}quadraticCurveTo(e,n,r,i){this._append`Q${+e},${+n},${this._x1=+r},${this._y1=+i}`}bezierCurveTo(e,n,r,i,o,s){this._append`C${+e},${+n},${+r},${+i},${this._x1=+o},${this._y1=+s}`}arcTo(e,n,r,i,o){if(e=+e,n=+n,r=+r,i=+i,o=+o,o<0)throw new Error(`negative radius: ${o}`);let s=this._x1,a=this._y1,l=r-e,u=i-n,c=s-e,f=a-n,h=c*c+f*f;if(this._x1===null)this._append`M${this._x1=e},${this._y1=n}`;else if(h>Xi)if(!(Math.abs(f*l-u*c)>Xi)||!o)this._append`L${this._x1=e},${this._y1=n}`;else{let d=r-s,x=i-a,p=l*l+u*u,g=d*d+x*x,m=Math.sqrt(p),b=Math.sqrt(h),v=o*Math.tan((hd-Math.acos((p+h-g)/(2*m*b)))/2),_=v/b,M=v/m;Math.abs(_-1)>Xi&&this._append`L${e+_*c},${n+_*f}`,this._append`A${o},${o},0,0,${+(f*d>c*x)},${this._x1=e+M*l},${this._y1=n+M*u}`}}arc(e,n,r,i,o,s){if(e=+e,n=+n,r=+r,s=!!s,r<0)throw new Error(`negative radius: ${r}`);let a=r*Math.cos(i),l=r*Math.sin(i),u=e+a,c=n+l,f=1^s,h=s?i-o:o-i;this._x1===null?this._append`M${u},${c}`:(Math.abs(this._x1-u)>Xi||Math.abs(this._y1-c)>Xi)&&this._append`L${u},${c}`,r&&(h<0&&(h=h%dd+dd),h>xA?this._append`A${r},${r},0,1,${f},${e-a},${n-l}A${r},${r},0,1,${f},${this._x1=u},${this._y1=c}`:h>Xi&&this._append`A${r},${r},0,${+(h>=hd)},${f},${this._x1=e+r*Math.cos(o)},${this._y1=n+r*Math.sin(o)}`)}rect(e,n,r,i){this._append`M${this._x0=this._x1=+e},${this._y0=this._y1=+n}h${r=+r}v${+i}h${-r}Z`}toString(){return this._}};function Bx(){return new Yi}Bx.prototype=Yi.prototype;function Ux(t){return Math.abs(t=Math.round(t))>=1e21?t.toLocaleString("en").replace(/,/g,""):t.toString(10)}function Zi(t,e){if(!isFinite(t)||t===0)return null;var n=(t=e?t.toExponential(e-1):t.toExponential()).indexOf("e"),r=t.slice(0,n);return[r.length>1?r[0]+r.slice(2):r,+t.slice(n+1)]}function mr(t){return t=Zi(Math.abs(t)),t?t[1]:NaN}function Ox(t,e){return function(n,r){for(var i=n.length,o=[],s=0,a=t[0],l=0;i>0&&a>0&&(l+a+1>r&&(a=Math.max(1,r-l)),o.push(n.substring(i-=a,i+a)),!((l+=a+1)>r));)a=t[s=(s+1)%t.length];return o.reverse().join(e)}}function zx(t){return function(e){return e.replace(/[0-9]/g,function(n){return t[+n]})}}var _A=/^(?:(.)?([<>=^]))?([+\-( ])?([$#])?(0)?(\d+)?(,)?(\.\d+)?(~)?([a-z%])?$/i;function oi(t){if(!(e=_A.exec(t)))throw new Error("invalid format: "+t);var e;return new lc({fill:e[1],align:e[2],sign:e[3],symbol:e[4],zero:e[5],width:e[6],comma:e[7],precision:e[8]&&e[8].slice(1),trim:e[9],type:e[10]})}oi.prototype=lc.prototype;function lc(t){this.fill=t.fill===void 0?" ":t.fill+"",this.align=t.align===void 0?">":t.align+"",this.sign=t.sign===void 0?"-":t.sign+"",this.symbol=t.symbol===void 0?"":t.symbol+"",this.zero=!!t.zero,this.width=t.width===void 0?void 0:+t.width,this.comma=!!t.comma,this.precision=t.precision===void 0?void 0:+t.precision,this.trim=!!t.trim,this.type=t.type===void 0?"":t.type+""}lc.prototype.toString=function(){return this.fill+this.align+this.sign+this.symbol+(this.zero?"0":"")+(this.width===void 0?"":Math.max(1,this.width|0))+(this.comma?",":"")+(this.precision===void 0?"":"."+Math.max(0,this.precision|0))+(this.trim?"~":"")+this.type};function kx(t){e:for(var e=t.length,n=1,r=-1,i;n<e;++n)switch(t[n]){case".":r=i=n;break;case"0":r===0&&(r=n),i=n;break;default:if(!+t[n])break e;r>0&&(r=0);break}return r>0?t.slice(0,r)+t.slice(i+1):t}var ma;function Vx(t,e){var n=Zi(t,e);if(!n)return ma=void 0,t.toPrecision(e);var r=n[0],i=n[1],o=i-(ma=Math.max(-8,Math.min(8,Math.floor(i/3)))*3)+1,s=r.length;return o===s?r:o>s?r+new Array(o-s+1).join("0"):o>0?r.slice(0,o)+"."+r.slice(o):"0."+new Array(1-o).join("0")+Zi(t,Math.max(0,e+o-1))[0]}function pd(t,e){var n=Zi(t,e);if(!n)return t+"";var r=n[0],i=n[1];return i<0?"0."+new Array(-i).join("0")+r:r.length>i+1?r.slice(0,i+1)+"."+r.slice(i+1):r+new Array(i-r.length+2).join("0")}var md={"%":(t,e)=>(t*100).toFixed(e),b:t=>Math.round(t).toString(2),c:t=>t+"",d:Ux,e:(t,e)=>t.toExponential(e),f:(t,e)=>t.toFixed(e),g:(t,e)=>t.toPrecision(e),o:t=>Math.round(t).toString(8),p:(t,e)=>pd(t*100,e),r:pd,s:Vx,X:t=>Math.round(t).toString(16).toUpperCase(),x:t=>Math.round(t).toString(16)};function gd(t){return t}var Hx=Array.prototype.map,Gx=["y","z","a","f","p","n","\xB5","m","","k","M","G","T","P","E","Z","Y"];function Wx(t){var e=t.grouping===void 0||t.thousands===void 0?gd:Ox(Hx.call(t.grouping,Number),t.thousands+""),n=t.currency===void 0?"":t.currency[0]+"",r=t.currency===void 0?"":t.currency[1]+"",i=t.decimal===void 0?".":t.decimal+"",o=t.numerals===void 0?gd:zx(Hx.call(t.numerals,String)),s=t.percent===void 0?"%":t.percent+"",a=t.minus===void 0?"\u2212":t.minus+"",l=t.nan===void 0?"NaN":t.nan+"";function u(f,h){f=oi(f);var d=f.fill,x=f.align,p=f.sign,g=f.symbol,m=f.zero,b=f.width,v=f.comma,_=f.precision,M=f.trim,y=f.type;y==="n"?(v=!0,y="g"):md[y]||(_===void 0&&(_=12),M=!0,y="g"),(m||d==="0"&&x==="=")&&(m=!0,d="0",x="=");var E=(h&&h.prefix!==void 0?h.prefix:"")+(g==="$"?n:g==="#"&&/[boxX]/.test(y)?"0"+y.toLowerCase():""),D=(g==="$"?r:/[%p]/.test(y)?s:"")+(h&&h.suffix!==void 0?h.suffix:""),S=md[y],w=/[defgprs%]/.test(y);_=_===void 0?6:/[gprs]/.test(y)?Math.max(1,Math.min(21,_)):Math.max(0,Math.min(20,_));function C(F){var O=E,U=D,z,B,J;if(y==="c")U=S(F)+U,F="";else{F=+F;var H=F<0||1/F<0;if(F=isNaN(F)?l:S(Math.abs(F),_),M&&(F=kx(F)),H&&+F==0&&p!=="+"&&(H=!1),O=(H?p==="("?p:a:p==="-"||p==="("?"":p)+O,U=(y==="s"&&!isNaN(F)&&ma!==void 0?Gx[8+ma/3]:"")+U+(H&&p==="("?")":""),w){for(z=-1,B=F.length;++z<B;)if(J=F.charCodeAt(z),48>J||J>57){U=(J===46?i+F.slice(z+1):F.slice(z))+U,F=F.slice(0,z);break}}}v&&!m&&(F=e(F,1/0));var ne=O.length+F.length+U.length,se=ne<b?new Array(b-ne+1).join(d):"";switch(v&&m&&(F=e(se+F,se.length?b-U.length:1/0),se=""),x){case"<":F=O+F+U+se;break;case"=":F=O+se+F+U;break;case"^":F=se.slice(0,ne=se.length>>1)+O+F+U+se.slice(ne);break;default:F=se+O+F+U;break}return o(F)}return C.toString=function(){return f+""},C}function c(f,h){var d=Math.max(-8,Math.min(8,Math.floor(mr(h)/3)))*3,x=Math.pow(10,-d),p=u((f=oi(f),f.type="f",f),{suffix:Gx[8+d/3]});return function(g){return p(x*g)}}return{format:u,formatPrefix:c}}var cc,$i,fc;xd({thousands:",",grouping:[3],currency:["$",""]});function xd(t){return cc=Wx(t),$i=cc.format,fc=cc.formatPrefix,cc}function vd(t){return Math.max(0,-mr(Math.abs(t)))}function _d(t,e){return Math.max(0,Math.max(-8,Math.min(8,Math.floor(mr(e)/3)))*3-mr(Math.abs(t)))}function yd(t,e){return t=Math.abs(t),e=Math.abs(e)-t,Math.max(0,mr(e)-mr(t))+1}function qx(t,e){switch(arguments.length){case 0:break;case 1:this.range(t);break;default:this.range(e).domain(t);break}return this}function Md(t){return function(){return t}}function Sd(t){return+t}var Xx=[0,1];function Yo(t){return t}function wd(t,e){return(e-=t=+t)?function(n){return(n-t)/e}:Md(isNaN(e)?NaN:.5)}function yA(t,e){var n;return t>e&&(n=t,t=e,e=n),function(r){return Math.max(t,Math.min(e,r))}}function MA(t,e,n){var r=t[0],i=t[1],o=e[0],s=e[1];return i<r?(r=wd(i,r),o=n(s,o)):(r=wd(r,i),o=n(o,s)),function(a){return o(r(a))}}function SA(t,e,n){var r=Math.min(t.length,e.length)-1,i=new Array(r),o=new Array(r),s=-1;for(t[r]<t[0]&&(t=t.slice().reverse(),e=e.slice().reverse());++s<r;)i[s]=wd(t[s],t[s+1]),o[s]=n(e[s],e[s+1]);return function(a){var l=$h(t,a,1,r)-1;return o[l](i[l](a))}}function Yx(t,e){return e.domain(t.domain()).range(t.range()).interpolate(t.interpolate()).clamp(t.clamp()).unknown(t.unknown())}function wA(){var t=Xx,e=Xx,n=Wi,r,i,o,s=Yo,a,l,u;function c(){var h=Math.min(t.length,e.length);return s!==Yo&&(s=yA(t[0],t[h-1])),a=h>2?SA:MA,l=u=null,f}function f(h){return h==null||isNaN(h=+h)?o:(l||(l=a(t.map(r),e,n)))(r(s(h)))}return f.invert=function(h){return s(i((u||(u=a(e,t.map(r),$t)))(h)))},f.domain=function(h){return arguments.length?(t=Array.from(h,Sd),c()):t.slice()},f.range=function(h){return arguments.length?(e=Array.from(h),c()):e.slice()},f.rangeRound=function(h){return e=Array.from(h),n=sd,c()},f.clamp=function(h){return arguments.length?(s=h?!0:Yo,c()):s!==Yo},f.interpolate=function(h){return arguments.length?(n=h,c()):n},f.unknown=function(h){return arguments.length?(o=h,f):o},function(h,d){return r=h,i=d,c()}}function bd(){return wA()(Yo,Yo)}function Ed(t,e,n,r){var i=Jh(t,e,n),o;switch(r=oi(r??",f"),r.type){case"s":{var s=Math.max(Math.abs(t),Math.abs(e));return r.precision==null&&!isNaN(o=_d(i,s))&&(r.precision=o),fc(r,s)}case"":case"e":case"g":case"p":case"r":{r.precision==null&&!isNaN(o=yd(i,Math.max(Math.abs(t),Math.abs(e))))&&(r.precision=o-(r.type==="e"));break}case"f":case"%":{r.precision==null&&!isNaN(o=vd(i))&&(r.precision=o-(r.type==="%")*2);break}}return $i(r)}function bA(t){var e=t.domain;return t.ticks=function(n){var r=e();return Bl(r[0],r[r.length-1],n??10)},t.tickFormat=function(n,r){var i=e();return Ed(i[0],i[i.length-1],n??10,r)},t.nice=function(n){n==null&&(n=10);var r=e(),i=0,o=r.length-1,s=r[i],a=r[o],l,u,c=10;for(a<s&&(u=s,s=a,a=u,u=i,i=o,o=u);c-- >0;){if(u=Qs(s,a,n),u===l)return r[i]=s,r[o]=a,e(r);if(u>0)s=Math.floor(s/u)*u,a=Math.ceil(a/u)*u;else if(u<0)s=Math.ceil(s*u)/u,a=Math.floor(a*u)/u;else break;l=u}return t},t}function Zo(){var t=bd();return t.copy=function(){return Yx(t,Zo())},qx.apply(t,arguments),bA(t)}function Ji(t){return function(){return t}}function Zx(t){let e=3;return t.digits=function(n){if(!arguments.length)return e;if(n==null)e=null;else{let r=Math.floor(n);if(!(r>=0))throw new RangeError(`invalid digits: ${n}`);e=r}return t},()=>new Yi(e)}var BO=Array.prototype.slice;function $x(t){return typeof t=="object"&&"length"in t?t:Array.from(t)}function Jx(t){this._context=t}Jx.prototype={areaStart:function(){this._line=0},areaEnd:function(){this._line=NaN},lineStart:function(){this._point=0},lineEnd:function(){(this._line||this._line!==0&&this._point===1)&&this._context.closePath(),this._line=1-this._line},point:function(t,e){switch(t=+t,e=+e,this._point){case 0:this._point=1,this._line?this._context.lineTo(t,e):this._context.moveTo(t,e);break;case 1:this._point=2;default:this._context.lineTo(t,e);break}}};function Kx(t){return new Jx(t)}function Qx(t){return t[0]}function jx(t){return t[1]}function Dd(t,e){var n=Ji(!0),r=null,i=Kx,o=null,s=Zx(a);t=typeof t=="function"?t:t===void 0?Qx:Ji(t),e=typeof e=="function"?e:e===void 0?jx:Ji(e);function a(l){var u,c=(l=$x(l)).length,f,h=!1,d;for(r==null&&(o=i(d=s())),u=0;u<=c;++u)!(u<c&&n(f=l[u],u,l))===h&&((h=!h)?o.lineStart():o.lineEnd()),h&&o.point(+t(f,u,l),+e(f,u,l));if(d)return o=null,d+""||null}return a.x=function(l){return arguments.length?(t=typeof l=="function"?l:Ji(+l),a):t},a.y=function(l){return arguments.length?(e=typeof l=="function"?l:Ji(+l),a):e},a.defined=function(l){return arguments.length?(n=typeof l=="function"?l:Ji(!!l),a):n},a.curve=function(l){return arguments.length?(i=l,r!=null&&(o=i(r)),a):i},a.context=function(l){return arguments.length?(l==null?r=o=null:o=i(r=l),a):r},a}function si(t,e,n){this.k=t,this.x=e,this.y=n}si.prototype={constructor:si,scale:function(t){return t===1?this:new si(this.k*t,this.x,this.y)},translate:function(t,e){return t===0&e===0?this:new si(this.k,this.x+this.k*t,this.y+this.k*e)},apply:function(t){return[t[0]*this.k+this.x,t[1]*this.k+this.y]},applyX:function(t){return t*this.k+this.x},applyY:function(t){return t*this.k+this.y},invert:function(t){return[(t[0]-this.x)/this.k,(t[1]-this.y)/this.k]},invertX:function(t){return(t-this.x)/this.k},invertY:function(t){return(t-this.y)/this.k},rescaleX:function(t){return t.copy().domain(t.range().map(this.invertX,this).map(t.invert,t))},rescaleY:function(t){return t.copy().domain(t.range().map(this.invertY,this).map(t.invert,t))},toString:function(){return"translate("+this.x+","+this.y+") scale("+this.k+")"}};var Ad=new si(1,0,0);Cd.prototype=si.prototype;function Cd(t){for(;!t.__zoom;)if(!(t=t.parentNode))return Ad;return t.__zoom}/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var ev=(t,e,n=[])=>{let r=document.createElementNS("http://www.w3.org/2000/svg",t);return Object.keys(e).forEach(i=>{r.setAttribute(i,String(e[i]))}),n.length&&n.forEach(i=>{let o=ev(...i);r.appendChild(o)}),r},tv=([t,e,n])=>ev(t,e,n);/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var EA=t=>Array.from(t.attributes).reduce((e,n)=>(e[n.name]=n.value,e),{}),DA=t=>typeof t=="string"?t:!t||!t.class?"":t.class&&typeof t.class=="string"?t.class.split(" "):t.class&&Array.isArray(t.class)?t.class:"",AA=t=>t.flatMap(DA).map(n=>n.trim()).filter(Boolean).filter((n,r,i)=>i.indexOf(n)===r).join(" "),CA=t=>t.replace(/(\w)(\w*)(_|-|\s*)/g,(e,n,r)=>n.toUpperCase()+r.toLowerCase()),Td=(t,{nameAttr:e,icons:n,attrs:r})=>{let i=t.getAttribute(e);if(i==null)return;let o=CA(i),s=n[o];if(!s)return console.warn(`${t.outerHTML} icon name was not found in the provided icons object.`);let a=EA(t),[l,u,c]=s,f={...u,"data-lucide":i,...r,...a},h=AA(["lucide",`lucide-${i}`,a,r]);h&&Object.assign(f,{class:h});let d=tv([l,f,c]);return t.parentNode?.replaceChild(d,t)};/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Gn={xmlns:"http://www.w3.org/2000/svg",width:24,height:24,viewBox:"0 0 24 24",fill:"none",stroke:"currentColor","stroke-width":2,"stroke-linecap":"round","stroke-linejoin":"round"};/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Rd=["svg",Gn,[["path",{d:"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"}],["polyline",{points:"7 10 12 15 17 10"}],["line",{x1:"12",x2:"12",y1:"15",y2:"3"}]]];/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Fd=["svg",Gn,[["rect",{x:"14",y:"4",width:"4",height:"16",rx:"1"}],["rect",{x:"6",y:"4",width:"4",height:"16",rx:"1"}]]];/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Pd=["svg",Gn,[["polygon",{points:"6 3 20 12 6 21 6 3"}]]];/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Id=["svg",Gn,[["path",{d:"M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"}],["path",{d:"M3 3v5h5"}]]];/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Nd=["svg",Gn,[["path",{d:"M3 7V5a2 2 0 0 1 2-2h2"}],["path",{d:"M17 3h2a2 2 0 0 1 2 2v2"}],["path",{d:"M21 17v2a2 2 0 0 1-2 2h-2"}],["path",{d:"M7 21H5a2 2 0 0 1-2-2v-2"}]]];/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var Ld=["svg",Gn,[["line",{x1:"6",x2:"6",y1:"4",y2:"20"}],["polygon",{points:"10,4 20,12 10,20"}]]];/**
 * @license lucide v0.468.0 - ISC
 *
 * This source code is licensed under the ISC license.
 * See the LICENSE file in the root directory of this source tree.
 */var nv=({icons:t={},nameAttr:e="data-lucide",attrs:n={}}={})=>{if(!Object.values(t).length)throw new Error(`Please provide an icons object.
If you want to use all the icons you can import it like:
 \`import { createIcons, icons } from 'lucide';
lucide.createIcons({icons});\``);if(typeof document>"u")throw new Error("`createIcons()` only works in a browser environment.");let r=document.querySelectorAll(`[${e}]`);if(Array.from(r).forEach(i=>Td(i,{nameAttr:e,icons:t,attrs:n})),e==="data-lucide"){let i=document.querySelectorAll("[icon-name]");i.length>0&&(console.warn("[Lucide] Some icons were found with the now deprecated icon-name attribute. These will still be replaced for backwards compatibility, but will no longer be supported in v1.0 and you should switch to data-lucide"),Array.from(i).forEach(o=>Td(o,{nameAttr:"icon-name",icons:t,attrs:n})))}};function $o(){return $o=Object.assign?Object.assign.bind():function(t){for(var e=1;e<arguments.length;e++){var n=arguments[e];for(var r in n)({}).hasOwnProperty.call(n,r)&&(t[r]=n[r])}return t},$o.apply(null,arguments)}var hc={relTol:1e-12,absTol:1e-15,matrix:"Matrix",number:"number",numberFallback:"number",precision:64,predictable:!1,randomSeed:null};function rv(t,e){if(ga(t,e))return t[e];throw typeof t[e]=="function"&&TA(t,e)?new Error('Cannot access method "'+e+'" as a property'):new Error('No access to property "'+e+'"')}function iv(t,e,n){if(ga(t,e))return t[e]=n,n;throw new Error('No access to property "'+e+'"')}function ga(t,e){return!RA(t)&&!Array.isArray(t)?!1:dn(FA,e)?!0:!(e in Object.prototype||e in Function.prototype)}function TA(t,e){return t==null||typeof t[e]!="function"||dn(t,e)&&Object.getPrototypeOf&&e in Object.getPrototypeOf(t)?!1:dn(PA,e)?!0:!(e in Object.prototype||e in Function.prototype)}function RA(t){return typeof t=="object"&&t&&t.constructor===Object}var FA={length:!0,name:!0},PA={toString:!0,valueOf:!0,toLocaleString:!0};var dc=class{constructor(e){this.wrappedObject=e,this[Symbol.iterator]=this.entries}keys(){return Object.keys(this.wrappedObject).filter(e=>this.has(e)).values()}get(e){return rv(this.wrappedObject,e)}set(e,n){return iv(this.wrappedObject,e,n),this}has(e){return ga(this.wrappedObject,e)&&e in this.wrappedObject}entries(){return IA(this.keys(),e=>[e,this.get(e)])}forEach(e){for(var n of this.keys())e(this.get(n),n,this)}delete(e){ga(this.wrappedObject,e)&&delete this.wrappedObject[e]}clear(){for(var e of this.keys())this.delete(e)}get size(){return Object.keys(this.wrappedObject).length}};function IA(t,e){return{next:()=>{var n=t.next();return n.done?n:{value:e(n.value),done:!1}}}}function ot(t){return typeof t=="number"}function st(t){return!t||typeof t!="object"||typeof t.constructor!="function"?!1:t.isBigNumber===!0&&typeof t.constructor.prototype=="object"&&t.constructor.prototype.isBigNumber===!0||typeof t.constructor.isDecimal=="function"&&t.constructor.isDecimal(t)===!0}function pc(t){return typeof t=="bigint"}function Ki(t){return t&&typeof t=="object"&&Object.getPrototypeOf(t).isComplex===!0||!1}function Qi(t){return t&&typeof t=="object"&&Object.getPrototypeOf(t).isFraction===!0||!1}function ui(t){return t&&t.constructor.prototype.isUnit===!0||!1}function Kt(t){return typeof t=="string"}var bt=Array.isArray;function at(t){return t&&t.constructor.prototype.isMatrix===!0||!1}function gr(t){return Array.isArray(t)||at(t)}function mc(t){return t&&t.isDenseMatrix&&t.constructor.prototype.isMatrix===!0||!1}function Jo(t){return t&&t.isSparseMatrix&&t.constructor.prototype.isMatrix===!0||!1}function gc(t){return t&&t.constructor.prototype.isRange===!0||!1}function li(t){return t&&t.constructor.prototype.isIndex===!0||!1}function xc(t){return typeof t=="boolean"}function vc(t){return t&&t.constructor.prototype.isResultSet===!0||!1}function _c(t){return t&&t.constructor.prototype.isHelp===!0||!1}function yc(t){return typeof t=="function"}function Mc(t){return t instanceof Date}function Sc(t){return t instanceof RegExp}function rr(t){return!!(t&&typeof t=="object"&&t.constructor===Object&&!Ki(t)&&!Qi(t))}function ai(t){return t?t instanceof Map||t instanceof dc||typeof t.set=="function"&&typeof t.get=="function"&&typeof t.keys=="function"&&typeof t.has=="function":!1}function ov(t){return ai(t)&&ai(t.a)&&ai(t.b)}function sv(t){return ai(t)&&rr(t.wrappedObject)}function wc(t){return t===null}function bc(t){return t===void 0}function Ec(t){return t&&t.isAccessorNode===!0&&t.constructor.prototype.isNode===!0||!1}function Dc(t){return t&&t.isArrayNode===!0&&t.constructor.prototype.isNode===!0||!1}function Ac(t){return t&&t.isAssignmentNode===!0&&t.constructor.prototype.isNode===!0||!1}function Cc(t){return t&&t.isBlockNode===!0&&t.constructor.prototype.isNode===!0||!1}function Tc(t){return t&&t.isConditionalNode===!0&&t.constructor.prototype.isNode===!0||!1}function Rc(t){return t&&t.isConstantNode===!0&&t.constructor.prototype.isNode===!0||!1}function Fc(t){return t&&t.isFunctionAssignmentNode===!0&&t.constructor.prototype.isNode===!0||!1}function Pc(t){return t&&t.isFunctionNode===!0&&t.constructor.prototype.isNode===!0||!1}function Ic(t){return t&&t.isIndexNode===!0&&t.constructor.prototype.isNode===!0||!1}function Nc(t){return t&&t.isNode===!0&&t.constructor.prototype.isNode===!0||!1}function Lc(t){return t&&t.isObjectNode===!0&&t.constructor.prototype.isNode===!0||!1}function Bc(t){return t&&t.isOperatorNode===!0&&t.constructor.prototype.isNode===!0||!1}function Uc(t){return t&&t.isParenthesisNode===!0&&t.constructor.prototype.isNode===!0||!1}function Oc(t){return t&&t.isRangeNode===!0&&t.constructor.prototype.isNode===!0||!1}function zc(t){return t&&t.isRelationalNode===!0&&t.constructor.prototype.isNode===!0||!1}function kc(t){return t&&t.isSymbolNode===!0&&t.constructor.prototype.isNode===!0||!1}function Vc(t){return t&&t.constructor.prototype.isChain===!0||!1}function Fn(t){var e=typeof t;return e==="object"?t===null?"null":st(t)?"BigNumber":t.constructor&&t.constructor.name?t.constructor.name:"Object":e}function ft(t){var e=typeof t;if(e==="number"||e==="bigint"||e==="string"||e==="boolean"||t===null||t===void 0)return t;if(typeof t.clone=="function")return t.clone();if(Array.isArray(t))return t.map(function(n){return ft(n)});if(t instanceof Date)return new Date(t.valueOf());if(st(t))return t;if(rr(t))return NA(t,ft);if(e==="function")return t;throw new TypeError("Cannot clone: unknown type of value (value: ".concat(t,")"))}function NA(t,e){var n={};for(var r in t)dn(t,r)&&(n[r]=e(t[r]));return n}function av(t,e){for(var n in e)dn(e,n)&&(t[n]=e[n]);return t}function Bd(t,e){if(Array.isArray(e))throw new TypeError("Arrays are not supported by deepExtend");for(var n in e)if(dn(e,n)&&!(n in Object.prototype)&&!(n in Function.prototype))if(e[n]&&e[n].constructor===Object)t[n]===void 0&&(t[n]={}),t[n]&&t[n].constructor===Object?Bd(t[n],e[n]):t[n]=e[n];else{if(Array.isArray(e[n]))throw new TypeError("Arrays are not supported by deepExtend");t[n]=e[n]}return t}function Wn(t,e){var n,r,i;if(Array.isArray(t)){if(!Array.isArray(e)||t.length!==e.length)return!1;for(r=0,i=t.length;r<i;r++)if(!Wn(t[r],e[r]))return!1;return!0}else{if(typeof t=="function")return t===e;if(t instanceof Object){if(Array.isArray(e)||!(e instanceof Object))return!1;for(n in t)if(!(n in e)||!Wn(t[n],e[n]))return!1;for(n in e)if(!(n in t))return!1;return!0}else return t===e}}function uv(t){var e={};return lv(t,e),e}function lv(t,e){for(var n in t)if(dn(t,n)){var r=t[n];typeof r=="object"&&r!==null?lv(r,e):e[n]=r}}function ji(t,e,n){var r=!0,i;Object.defineProperty(t,e,{get:function(){return r&&(i=n(),r=!1),i},set:function(s){i=s,r=!1},configurable:!0,enumerable:!0})}function dn(t,e){return t&&Object.hasOwnProperty.call(t,e)}function cv(t){return t&&typeof t.factory=="function"}function fv(t,e){for(var n={},r=0;r<e.length;r++){var i=e[r],o=t[i];o!==void 0&&(n[i]=o)}return n}var hv=["Matrix","Array"],dv=["number","BigNumber","bigint","Fraction"];function mv(t,e){function n(r){if(r){if(r.epsilon!==void 0){console.warn('Warning: The configuration option "epsilon" is deprecated. Use "relTol" and "absTol" instead.');var i=ft(r);return i.relTol=r.epsilon,i.absTol=r.epsilon*.001,delete i.epsilon,n(i)}var o=ft(t);pv(r,"matrix",hv),pv(r,"number",dv),Bd(t,r);var s=ft(t),a=ft(r);return e("config",s,o,a),s}else return ft(t)}return n.MATRIX_OPTIONS=hv,n.NUMBER_OPTIONS=dv,Object.keys(hc).forEach(r=>{Object.defineProperty(n,r,{get:()=>t[r],enumerable:!0,configurable:!0})}),n}function pv(t,e,n){t[e]!==void 0&&!n.includes(t[e])&&console.warn('Warning: Unknown value "'+t[e]+'" for configuration option "'+e+'". Available options: '+n.map(r=>JSON.stringify(r)).join(", ")+".")}var Hd=Pa(Hc(),1);function ve(t,e,n,r){function i(o){var s=fv(o,e.map(zd));return LA(t,e,o),n(s)}return i.isFactory=!0,i.fn=t,i.dependencies=e.slice().sort(),r&&(i.meta=r),i}function eo(t){return typeof t=="function"&&typeof t.fn=="string"&&Array.isArray(t.dependencies)}function LA(t,e,n){var r=e.filter(o=>!BA(o)).every(o=>n[o]!==void 0);if(!r){var i=e.filter(o=>n[o]===void 0);throw new Error('Cannot create function "'.concat(t,'", ')+"some dependencies are missing: ".concat(i.map(o=>'"'.concat(o,'"')).join(", "),"."))}}function BA(t){return t&&t[0]==="?"}function zd(t){return t&&t[0]==="?"?t.slice(1):t}function ht(t){return typeof t=="boolean"?!0:isFinite(t)?t===Math.round(t):!1}var vv=Math.sign||function(t){return t>0?1:t<0?-1:0},_v=Math.log2||function(e){return Math.log(e)/Math.LN2},yv=Math.log10||function(e){return Math.log(e)/Math.LN10},Mv=Math.log1p||function(t){return Math.log(t+1)},Sv=Math.cbrt||function(e){if(e===0)return e;var n=e<0,r;return n&&(e=-e),isFinite(e)?(r=Math.exp(Math.log(e)/3),r=(e/(r*r)+2*r)/3):r=e,n?-r:r},wv=Math.expm1||function(e){return e>=2e-4||e<=-2e-4?Math.exp(e)-1:e+e*e/2+e*e*e/6};function kd(t,e,n){var r={2:"0b",8:"0o",16:"0x"},i=r[e],o="";if(n){if(n<1)throw new Error("size must be in greater than 0");if(!ht(n))throw new Error("size must be an integer");if(t>2**(n-1)-1||t<-(2**(n-1)))throw new Error("Value must be in range [-2^".concat(n-1,", 2^").concat(n-1,"-1]"));if(!ht(t))throw new Error("Value must be an integer");t<0&&(t=t+2**n),o="i".concat(n)}var s="";return t<0&&(t=-t,s="-"),"".concat(s).concat(i).concat(t.toString(e)).concat(o)}function xa(t,e){if(typeof e=="function")return e(t);if(t===1/0)return"Infinity";if(t===-1/0)return"-Infinity";if(isNaN(t))return"NaN";var{notation:n,precision:r,wordSize:i}=Vd(e);switch(n){case"fixed":return bv(t,r);case"exponential":return Ev(t,r);case"engineering":return UA(t,r);case"bin":return kd(t,2,i);case"oct":return kd(t,8,i);case"hex":return kd(t,16,i);case"auto":return OA(t,r,e).replace(/((\.\d*?)(0+))($|e)/,function(){var o=arguments[2],s=arguments[4];return o!=="."?o+s:s});default:throw new Error('Unknown notation "'+n+'". Choose "auto", "exponential", "fixed", "bin", "oct", or "hex.')}}function Vd(t){var e="auto",n,r;if(t!==void 0)if(ot(t))n=t;else if(st(t))n=t.toNumber();else if(rr(t))t.precision!==void 0&&(n=gv(t.precision,()=>{throw new Error('Option "precision" must be a number or BigNumber')})),t.wordSize!==void 0&&(r=gv(t.wordSize,()=>{throw new Error('Option "wordSize" must be a number or BigNumber')})),t.notation&&(e=t.notation);else throw new Error("Unsupported type of options, number, BigNumber, or object expected");return{notation:e,precision:n,wordSize:r}}function Gc(t){var e=String(t).toLowerCase().match(/^(-?)(\d+\.?\d*)(e([+-]?\d+))?$/);if(!e)throw new SyntaxError("Invalid number "+t);var n=e[1],r=e[2],i=parseFloat(e[4]||"0"),o=r.indexOf(".");i+=o!==-1?o-1:r.length-1;var s=r.replace(".","").replace(/^0*/,function(a){return i-=a.length,""}).replace(/0*$/,"").split("").map(function(a){return parseInt(a)});return s.length===0&&(s.push(0),i++),{sign:n,coefficients:s,exponent:i}}function UA(t,e){if(isNaN(t)||!isFinite(t))return String(t);var n=Gc(t),r=Wc(n,e),i=r.exponent,o=r.coefficients,s=i%3===0?i:i<0?i-3-i%3:i-i%3;if(ot(e))for(;e>o.length||i-s+1>o.length;)o.push(0);else for(var a=Math.abs(i-s)-(o.length-1),l=0;l<a;l++)o.push(0);for(var u=Math.abs(i-s),c=1;u>0;)c++,u--;var f=o.slice(c).join(""),h=ot(e)&&f.length||f.match(/[1-9]/)?"."+f:"",d=o.slice(0,c).join("")+h+"e"+(i>=0?"+":"")+s.toString();return r.sign+d}function bv(t,e){if(isNaN(t)||!isFinite(t))return String(t);var n=Gc(t),r=typeof e=="number"?Wc(n,n.exponent+1+e):n,i=r.coefficients,o=r.exponent+1,s=o+(e||0);return i.length<s&&(i=i.concat(Ko(s-i.length))),o<0&&(i=Ko(-o+1).concat(i),o=1),o<i.length&&i.splice(o,0,o===0?"0.":"."),r.sign+i.join("")}function Ev(t,e){if(isNaN(t)||!isFinite(t))return String(t);var n=Gc(t),r=e?Wc(n,e):n,i=r.coefficients,o=r.exponent;i.length<e&&(i=i.concat(Ko(e-i.length)));var s=i.shift();return r.sign+s+(i.length>0?"."+i.join(""):"")+"e"+(o>=0?"+":"")+o}function OA(t,e,n){if(isNaN(t)||!isFinite(t))return String(t);var r=xv(n?.lowerExp,-3),i=xv(n?.upperExp,5),o=Gc(t),s=e?Wc(o,e):o;if(s.exponent<r||s.exponent>=i)return Ev(t,e);var a=s.coefficients,l=s.exponent;a.length<e&&(a=a.concat(Ko(e-a.length))),a=a.concat(Ko(l-a.length+1+(a.length<e?e-a.length:0))),a=Ko(-l).concat(a);var u=l>0?l:0;return u<a.length-1&&a.splice(u+1,0,"."),s.sign+a.join("")}function Wc(t,e){for(var n={sign:t.sign,coefficients:t.coefficients,exponent:t.exponent},r=n.coefficients;e<=0;)r.unshift(0),n.exponent++,e++;if(r.length>e){var i=r.splice(e,r.length-e);if(i[0]>=5){var o=e-1;for(r[o]++;r[o]===10;)r.pop(),o===0&&(r.unshift(0),n.exponent++,o++),o--,r[o]++}}return n}function Ko(t){for(var e=[],n=0;n<t;n++)e.push(0);return e}function Dv(t){return t.toExponential().replace(/e.*$/,"").replace(/^0\.?0*|\./,"").length}function Qo(t,e){var n=arguments.length>2&&arguments[2]!==void 0?arguments[2]:1e-8,r=arguments.length>3&&arguments[3]!==void 0?arguments[3]:0;if(n<=0)throw new Error("Relative tolerance must be greater than 0");if(r<0)throw new Error("Absolute tolerance must be at least 0");return isNaN(t)||isNaN(e)?!1:!isFinite(t)||!isFinite(e)?t===e:t===e?!0:Math.abs(t-e)<=Math.max(n*Math.max(Math.abs(t),Math.abs(e)),r)}function gv(t,e){if(ot(t))return t;if(st(t))return t.toNumber();e()}function xv(t,e){return ot(t)?t:st(t)?t.toNumber():e}var Av=function(){return Av=Hd.default.create,Hd.default},zA=["?BigNumber","?Complex","?DenseMatrix","?Fraction"],Gd=ve("typed",zA,function(e){var{BigNumber:n,Complex:r,DenseMatrix:i,Fraction:o}=e,s=Av();return s.clear(),s.addTypes([{name:"number",test:ot},{name:"Complex",test:Ki},{name:"BigNumber",test:st},{name:"bigint",test:pc},{name:"Fraction",test:Qi},{name:"Unit",test:ui},{name:"identifier",test:a=>Kt&&/^(?:[A-Za-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0560-\u0588\u05D0-\u05EA\u05EF-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u0860-\u086A\u0870-\u0887\u0889-\u088E\u08A0-\u08C9\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u09FC\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C5D\u0C60\u0C61\u0C80\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D04-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D54-\u0D56\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E86-\u0E8A\u0E8C-\u0EA3\u0EA5\u0EA7-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u1711\u171F-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1878\u1880-\u1884\u1887-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4C\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1C80-\u1C8A\u1C90-\u1CBA\u1CBD-\u1CBF\u1CE9-\u1CEC\u1CEE-\u1CF3\u1CF5\u1CF6\u1CFA\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2183\u2184\u2C00-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005\u3006\u3031-\u3035\u303B\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312F\u3131-\u318E\u31A0-\u31BF\u31F0-\u31FF\u3400-\u4DBF\u4E00-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6E5\uA717-\uA71F\uA722-\uA788\uA78B-\uA7CD\uA7D0\uA7D1\uA7D3\uA7D5-\uA7DC\uA7F2-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA8FE\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB69\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF2D-\uDF40\uDF42-\uDF49\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF]|\uD801[\uDC00-\uDC9D\uDCB0-\uDCD3\uDCD8-\uDCFB\uDD00-\uDD27\uDD30-\uDD63\uDD70-\uDD7A\uDD7C-\uDD8A\uDD8C-\uDD92\uDD94\uDD95\uDD97-\uDDA1\uDDA3-\uDDB1\uDDB3-\uDDB9\uDDBB\uDDBC\uDDC0-\uDDF3\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67\uDF80-\uDF85\uDF87-\uDFB0\uDFB2-\uDFBA]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE35\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2\uDD00-\uDD23\uDD4A-\uDD65\uDD6F-\uDD85\uDE80-\uDEA9\uDEB0\uDEB1\uDEC2-\uDEC4\uDF00-\uDF1C\uDF27\uDF30-\uDF45\uDF70-\uDF81\uDFB0-\uDFC4\uDFE0-\uDFF6]|\uD804[\uDC03-\uDC37\uDC71\uDC72\uDC75\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD44\uDD47\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE3F\uDE40\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61\uDF80-\uDF89\uDF8B\uDF8E\uDF90-\uDFB5\uDFB7\uDFD1\uDFD3]|\uD805[\uDC00-\uDC34\uDC47-\uDC4A\uDC5F-\uDC61\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDEB8\uDF00-\uDF1A\uDF40-\uDF46]|\uD806[\uDC00-\uDC2B\uDCA0-\uDCDF\uDCFF-\uDD06\uDD09\uDD0C-\uDD13\uDD15\uDD16\uDD18-\uDD2F\uDD3F\uDD41\uDDA0-\uDDA7\uDDAA-\uDDD0\uDDE1\uDDE3\uDE00\uDE0B-\uDE32\uDE3A\uDE50\uDE5C-\uDE89\uDE9D\uDEB0-\uDEF8\uDFC0-\uDFE0]|\uD807[\uDC00-\uDC08\uDC0A-\uDC2E\uDC40\uDC72-\uDC8F\uDD00-\uDD06\uDD08\uDD09\uDD0B-\uDD30\uDD46\uDD60-\uDD65\uDD67\uDD68\uDD6A-\uDD89\uDD98\uDEE0-\uDEF2\uDF02\uDF04-\uDF10\uDF12-\uDF33\uDFB0]|\uD808[\uDC00-\uDF99]|\uD809[\uDC80-\uDD43]|\uD80B[\uDF90-\uDFF0]|[\uD80C\uD80E\uD80F\uD81C-\uD820\uD822\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883\uD885-\uD887][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2F\uDC41-\uDC46\uDC60-\uDFFF]|\uD810[\uDC00-\uDFFA]|\uD811[\uDC00-\uDE46]|\uD818[\uDD00-\uDD1D]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE70-\uDEBE\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDD40-\uDD6C\uDE40-\uDE7F\uDF00-\uDF4A\uDF50\uDF93-\uDF9F\uDFE0\uDFE1\uDFE3]|\uD821[\uDC00-\uDFF7]|\uD823[\uDC00-\uDCD5\uDCFF-\uDD08]|\uD82B[\uDFF0-\uDFF3\uDFF5-\uDFFB\uDFFD\uDFFE]|\uD82C[\uDC00-\uDD22\uDD32\uDD50-\uDD52\uDD55\uDD64-\uDD67\uDD70-\uDEFB]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD837[\uDF00-\uDF1E\uDF25-\uDF2A]|\uD838[\uDC30-\uDC6D\uDD00-\uDD2C\uDD37-\uDD3D\uDD4E\uDE90-\uDEAD\uDEC0-\uDEEB]|\uD839[\uDCD0-\uDCEB\uDDD0-\uDDED\uDDF0\uDFE0-\uDFE6\uDFE8-\uDFEB\uDFED\uDFEE\uDFF0-\uDFFE]|\uD83A[\uDC00-\uDCC4\uDD00-\uDD43\uDD4B]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF39\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0\uDFF0-\uDFFF]|\uD87B[\uDC00-\uDE5D]|\uD87E[\uDC00-\uDE1D]|\uD884[\uDC00-\uDF4A\uDF50-\uDFFF]|\uD888[\uDC00-\uDFAF])(?:[0-9A-Za-z\xAA\xB5\xBA\xC0-\xD6\xD8-\xF6\xF8-\u02C1\u02C6-\u02D1\u02E0-\u02E4\u02EC\u02EE\u0370-\u0374\u0376\u0377\u037A-\u037D\u037F\u0386\u0388-\u038A\u038C\u038E-\u03A1\u03A3-\u03F5\u03F7-\u0481\u048A-\u052F\u0531-\u0556\u0559\u0560-\u0588\u05D0-\u05EA\u05EF-\u05F2\u0620-\u064A\u066E\u066F\u0671-\u06D3\u06D5\u06E5\u06E6\u06EE\u06EF\u06FA-\u06FC\u06FF\u0710\u0712-\u072F\u074D-\u07A5\u07B1\u07CA-\u07EA\u07F4\u07F5\u07FA\u0800-\u0815\u081A\u0824\u0828\u0840-\u0858\u0860-\u086A\u0870-\u0887\u0889-\u088E\u08A0-\u08C9\u0904-\u0939\u093D\u0950\u0958-\u0961\u0971-\u0980\u0985-\u098C\u098F\u0990\u0993-\u09A8\u09AA-\u09B0\u09B2\u09B6-\u09B9\u09BD\u09CE\u09DC\u09DD\u09DF-\u09E1\u09F0\u09F1\u09FC\u0A05-\u0A0A\u0A0F\u0A10\u0A13-\u0A28\u0A2A-\u0A30\u0A32\u0A33\u0A35\u0A36\u0A38\u0A39\u0A59-\u0A5C\u0A5E\u0A72-\u0A74\u0A85-\u0A8D\u0A8F-\u0A91\u0A93-\u0AA8\u0AAA-\u0AB0\u0AB2\u0AB3\u0AB5-\u0AB9\u0ABD\u0AD0\u0AE0\u0AE1\u0AF9\u0B05-\u0B0C\u0B0F\u0B10\u0B13-\u0B28\u0B2A-\u0B30\u0B32\u0B33\u0B35-\u0B39\u0B3D\u0B5C\u0B5D\u0B5F-\u0B61\u0B71\u0B83\u0B85-\u0B8A\u0B8E-\u0B90\u0B92-\u0B95\u0B99\u0B9A\u0B9C\u0B9E\u0B9F\u0BA3\u0BA4\u0BA8-\u0BAA\u0BAE-\u0BB9\u0BD0\u0C05-\u0C0C\u0C0E-\u0C10\u0C12-\u0C28\u0C2A-\u0C39\u0C3D\u0C58-\u0C5A\u0C5D\u0C60\u0C61\u0C80\u0C85-\u0C8C\u0C8E-\u0C90\u0C92-\u0CA8\u0CAA-\u0CB3\u0CB5-\u0CB9\u0CBD\u0CDD\u0CDE\u0CE0\u0CE1\u0CF1\u0CF2\u0D04-\u0D0C\u0D0E-\u0D10\u0D12-\u0D3A\u0D3D\u0D4E\u0D54-\u0D56\u0D5F-\u0D61\u0D7A-\u0D7F\u0D85-\u0D96\u0D9A-\u0DB1\u0DB3-\u0DBB\u0DBD\u0DC0-\u0DC6\u0E01-\u0E30\u0E32\u0E33\u0E40-\u0E46\u0E81\u0E82\u0E84\u0E86-\u0E8A\u0E8C-\u0EA3\u0EA5\u0EA7-\u0EB0\u0EB2\u0EB3\u0EBD\u0EC0-\u0EC4\u0EC6\u0EDC-\u0EDF\u0F00\u0F40-\u0F47\u0F49-\u0F6C\u0F88-\u0F8C\u1000-\u102A\u103F\u1050-\u1055\u105A-\u105D\u1061\u1065\u1066\u106E-\u1070\u1075-\u1081\u108E\u10A0-\u10C5\u10C7\u10CD\u10D0-\u10FA\u10FC-\u1248\u124A-\u124D\u1250-\u1256\u1258\u125A-\u125D\u1260-\u1288\u128A-\u128D\u1290-\u12B0\u12B2-\u12B5\u12B8-\u12BE\u12C0\u12C2-\u12C5\u12C8-\u12D6\u12D8-\u1310\u1312-\u1315\u1318-\u135A\u1380-\u138F\u13A0-\u13F5\u13F8-\u13FD\u1401-\u166C\u166F-\u167F\u1681-\u169A\u16A0-\u16EA\u16F1-\u16F8\u1700-\u1711\u171F-\u1731\u1740-\u1751\u1760-\u176C\u176E-\u1770\u1780-\u17B3\u17D7\u17DC\u1820-\u1878\u1880-\u1884\u1887-\u18A8\u18AA\u18B0-\u18F5\u1900-\u191E\u1950-\u196D\u1970-\u1974\u1980-\u19AB\u19B0-\u19C9\u1A00-\u1A16\u1A20-\u1A54\u1AA7\u1B05-\u1B33\u1B45-\u1B4C\u1B83-\u1BA0\u1BAE\u1BAF\u1BBA-\u1BE5\u1C00-\u1C23\u1C4D-\u1C4F\u1C5A-\u1C7D\u1C80-\u1C8A\u1C90-\u1CBA\u1CBD-\u1CBF\u1CE9-\u1CEC\u1CEE-\u1CF3\u1CF5\u1CF6\u1CFA\u1D00-\u1DBF\u1E00-\u1F15\u1F18-\u1F1D\u1F20-\u1F45\u1F48-\u1F4D\u1F50-\u1F57\u1F59\u1F5B\u1F5D\u1F5F-\u1F7D\u1F80-\u1FB4\u1FB6-\u1FBC\u1FBE\u1FC2-\u1FC4\u1FC6-\u1FCC\u1FD0-\u1FD3\u1FD6-\u1FDB\u1FE0-\u1FEC\u1FF2-\u1FF4\u1FF6-\u1FFC\u2071\u207F\u2090-\u209C\u2102\u2107\u210A-\u2113\u2115\u2119-\u211D\u2124\u2126\u2128\u212A-\u212D\u212F-\u2139\u213C-\u213F\u2145-\u2149\u214E\u2183\u2184\u2C00-\u2CE4\u2CEB-\u2CEE\u2CF2\u2CF3\u2D00-\u2D25\u2D27\u2D2D\u2D30-\u2D67\u2D6F\u2D80-\u2D96\u2DA0-\u2DA6\u2DA8-\u2DAE\u2DB0-\u2DB6\u2DB8-\u2DBE\u2DC0-\u2DC6\u2DC8-\u2DCE\u2DD0-\u2DD6\u2DD8-\u2DDE\u2E2F\u3005\u3006\u3031-\u3035\u303B\u303C\u3041-\u3096\u309D-\u309F\u30A1-\u30FA\u30FC-\u30FF\u3105-\u312F\u3131-\u318E\u31A0-\u31BF\u31F0-\u31FF\u3400-\u4DBF\u4E00-\uA48C\uA4D0-\uA4FD\uA500-\uA60C\uA610-\uA61F\uA62A\uA62B\uA640-\uA66E\uA67F-\uA69D\uA6A0-\uA6E5\uA717-\uA71F\uA722-\uA788\uA78B-\uA7CD\uA7D0\uA7D1\uA7D3\uA7D5-\uA7DC\uA7F2-\uA801\uA803-\uA805\uA807-\uA80A\uA80C-\uA822\uA840-\uA873\uA882-\uA8B3\uA8F2-\uA8F7\uA8FB\uA8FD\uA8FE\uA90A-\uA925\uA930-\uA946\uA960-\uA97C\uA984-\uA9B2\uA9CF\uA9E0-\uA9E4\uA9E6-\uA9EF\uA9FA-\uA9FE\uAA00-\uAA28\uAA40-\uAA42\uAA44-\uAA4B\uAA60-\uAA76\uAA7A\uAA7E-\uAAAF\uAAB1\uAAB5\uAAB6\uAAB9-\uAABD\uAAC0\uAAC2\uAADB-\uAADD\uAAE0-\uAAEA\uAAF2-\uAAF4\uAB01-\uAB06\uAB09-\uAB0E\uAB11-\uAB16\uAB20-\uAB26\uAB28-\uAB2E\uAB30-\uAB5A\uAB5C-\uAB69\uAB70-\uABE2\uAC00-\uD7A3\uD7B0-\uD7C6\uD7CB-\uD7FB\uF900-\uFA6D\uFA70-\uFAD9\uFB00-\uFB06\uFB13-\uFB17\uFB1D\uFB1F-\uFB28\uFB2A-\uFB36\uFB38-\uFB3C\uFB3E\uFB40\uFB41\uFB43\uFB44\uFB46-\uFBB1\uFBD3-\uFD3D\uFD50-\uFD8F\uFD92-\uFDC7\uFDF0-\uFDFB\uFE70-\uFE74\uFE76-\uFEFC\uFF21-\uFF3A\uFF41-\uFF5A\uFF66-\uFFBE\uFFC2-\uFFC7\uFFCA-\uFFCF\uFFD2-\uFFD7\uFFDA-\uFFDC]|\uD800[\uDC00-\uDC0B\uDC0D-\uDC26\uDC28-\uDC3A\uDC3C\uDC3D\uDC3F-\uDC4D\uDC50-\uDC5D\uDC80-\uDCFA\uDE80-\uDE9C\uDEA0-\uDED0\uDF00-\uDF1F\uDF2D-\uDF40\uDF42-\uDF49\uDF50-\uDF75\uDF80-\uDF9D\uDFA0-\uDFC3\uDFC8-\uDFCF]|\uD801[\uDC00-\uDC9D\uDCB0-\uDCD3\uDCD8-\uDCFB\uDD00-\uDD27\uDD30-\uDD63\uDD70-\uDD7A\uDD7C-\uDD8A\uDD8C-\uDD92\uDD94\uDD95\uDD97-\uDDA1\uDDA3-\uDDB1\uDDB3-\uDDB9\uDDBB\uDDBC\uDDC0-\uDDF3\uDE00-\uDF36\uDF40-\uDF55\uDF60-\uDF67\uDF80-\uDF85\uDF87-\uDFB0\uDFB2-\uDFBA]|\uD802[\uDC00-\uDC05\uDC08\uDC0A-\uDC35\uDC37\uDC38\uDC3C\uDC3F-\uDC55\uDC60-\uDC76\uDC80-\uDC9E\uDCE0-\uDCF2\uDCF4\uDCF5\uDD00-\uDD15\uDD20-\uDD39\uDD80-\uDDB7\uDDBE\uDDBF\uDE00\uDE10-\uDE13\uDE15-\uDE17\uDE19-\uDE35\uDE60-\uDE7C\uDE80-\uDE9C\uDEC0-\uDEC7\uDEC9-\uDEE4\uDF00-\uDF35\uDF40-\uDF55\uDF60-\uDF72\uDF80-\uDF91]|\uD803[\uDC00-\uDC48\uDC80-\uDCB2\uDCC0-\uDCF2\uDD00-\uDD23\uDD4A-\uDD65\uDD6F-\uDD85\uDE80-\uDEA9\uDEB0\uDEB1\uDEC2-\uDEC4\uDF00-\uDF1C\uDF27\uDF30-\uDF45\uDF70-\uDF81\uDFB0-\uDFC4\uDFE0-\uDFF6]|\uD804[\uDC03-\uDC37\uDC71\uDC72\uDC75\uDC83-\uDCAF\uDCD0-\uDCE8\uDD03-\uDD26\uDD44\uDD47\uDD50-\uDD72\uDD76\uDD83-\uDDB2\uDDC1-\uDDC4\uDDDA\uDDDC\uDE00-\uDE11\uDE13-\uDE2B\uDE3F\uDE40\uDE80-\uDE86\uDE88\uDE8A-\uDE8D\uDE8F-\uDE9D\uDE9F-\uDEA8\uDEB0-\uDEDE\uDF05-\uDF0C\uDF0F\uDF10\uDF13-\uDF28\uDF2A-\uDF30\uDF32\uDF33\uDF35-\uDF39\uDF3D\uDF50\uDF5D-\uDF61\uDF80-\uDF89\uDF8B\uDF8E\uDF90-\uDFB5\uDFB7\uDFD1\uDFD3]|\uD805[\uDC00-\uDC34\uDC47-\uDC4A\uDC5F-\uDC61\uDC80-\uDCAF\uDCC4\uDCC5\uDCC7\uDD80-\uDDAE\uDDD8-\uDDDB\uDE00-\uDE2F\uDE44\uDE80-\uDEAA\uDEB8\uDF00-\uDF1A\uDF40-\uDF46]|\uD806[\uDC00-\uDC2B\uDCA0-\uDCDF\uDCFF-\uDD06\uDD09\uDD0C-\uDD13\uDD15\uDD16\uDD18-\uDD2F\uDD3F\uDD41\uDDA0-\uDDA7\uDDAA-\uDDD0\uDDE1\uDDE3\uDE00\uDE0B-\uDE32\uDE3A\uDE50\uDE5C-\uDE89\uDE9D\uDEB0-\uDEF8\uDFC0-\uDFE0]|\uD807[\uDC00-\uDC08\uDC0A-\uDC2E\uDC40\uDC72-\uDC8F\uDD00-\uDD06\uDD08\uDD09\uDD0B-\uDD30\uDD46\uDD60-\uDD65\uDD67\uDD68\uDD6A-\uDD89\uDD98\uDEE0-\uDEF2\uDF02\uDF04-\uDF10\uDF12-\uDF33\uDFB0]|\uD808[\uDC00-\uDF99]|\uD809[\uDC80-\uDD43]|\uD80B[\uDF90-\uDFF0]|[\uD80C\uD80E\uD80F\uD81C-\uD820\uD822\uD840-\uD868\uD86A-\uD86C\uD86F-\uD872\uD874-\uD879\uD880-\uD883\uD885-\uD887][\uDC00-\uDFFF]|\uD80D[\uDC00-\uDC2F\uDC41-\uDC46\uDC60-\uDFFF]|\uD810[\uDC00-\uDFFA]|\uD811[\uDC00-\uDE46]|\uD818[\uDD00-\uDD1D]|\uD81A[\uDC00-\uDE38\uDE40-\uDE5E\uDE70-\uDEBE\uDED0-\uDEED\uDF00-\uDF2F\uDF40-\uDF43\uDF63-\uDF77\uDF7D-\uDF8F]|\uD81B[\uDD40-\uDD6C\uDE40-\uDE7F\uDF00-\uDF4A\uDF50\uDF93-\uDF9F\uDFE0\uDFE1\uDFE3]|\uD821[\uDC00-\uDFF7]|\uD823[\uDC00-\uDCD5\uDCFF-\uDD08]|\uD82B[\uDFF0-\uDFF3\uDFF5-\uDFFB\uDFFD\uDFFE]|\uD82C[\uDC00-\uDD22\uDD32\uDD50-\uDD52\uDD55\uDD64-\uDD67\uDD70-\uDEFB]|\uD82F[\uDC00-\uDC6A\uDC70-\uDC7C\uDC80-\uDC88\uDC90-\uDC99]|\uD835[\uDC00-\uDC54\uDC56-\uDC9C\uDC9E\uDC9F\uDCA2\uDCA5\uDCA6\uDCA9-\uDCAC\uDCAE-\uDCB9\uDCBB\uDCBD-\uDCC3\uDCC5-\uDD05\uDD07-\uDD0A\uDD0D-\uDD14\uDD16-\uDD1C\uDD1E-\uDD39\uDD3B-\uDD3E\uDD40-\uDD44\uDD46\uDD4A-\uDD50\uDD52-\uDEA5\uDEA8-\uDEC0\uDEC2-\uDEDA\uDEDC-\uDEFA\uDEFC-\uDF14\uDF16-\uDF34\uDF36-\uDF4E\uDF50-\uDF6E\uDF70-\uDF88\uDF8A-\uDFA8\uDFAA-\uDFC2\uDFC4-\uDFCB]|\uD837[\uDF00-\uDF1E\uDF25-\uDF2A]|\uD838[\uDC30-\uDC6D\uDD00-\uDD2C\uDD37-\uDD3D\uDD4E\uDE90-\uDEAD\uDEC0-\uDEEB]|\uD839[\uDCD0-\uDCEB\uDDD0-\uDDED\uDDF0\uDFE0-\uDFE6\uDFE8-\uDFEB\uDFED\uDFEE\uDFF0-\uDFFE]|\uD83A[\uDC00-\uDCC4\uDD00-\uDD43\uDD4B]|\uD83B[\uDE00-\uDE03\uDE05-\uDE1F\uDE21\uDE22\uDE24\uDE27\uDE29-\uDE32\uDE34-\uDE37\uDE39\uDE3B\uDE42\uDE47\uDE49\uDE4B\uDE4D-\uDE4F\uDE51\uDE52\uDE54\uDE57\uDE59\uDE5B\uDE5D\uDE5F\uDE61\uDE62\uDE64\uDE67-\uDE6A\uDE6C-\uDE72\uDE74-\uDE77\uDE79-\uDE7C\uDE7E\uDE80-\uDE89\uDE8B-\uDE9B\uDEA1-\uDEA3\uDEA5-\uDEA9\uDEAB-\uDEBB]|\uD869[\uDC00-\uDEDF\uDF00-\uDFFF]|\uD86D[\uDC00-\uDF39\uDF40-\uDFFF]|\uD86E[\uDC00-\uDC1D\uDC20-\uDFFF]|\uD873[\uDC00-\uDEA1\uDEB0-\uDFFF]|\uD87A[\uDC00-\uDFE0\uDFF0-\uDFFF]|\uD87B[\uDC00-\uDE5D]|\uD87E[\uDC00-\uDE1D]|\uD884[\uDC00-\uDF4A\uDF50-\uDFFF]|\uD888[\uDC00-\uDFAF])*$/.test(a)},{name:"string",test:Kt},{name:"Chain",test:Vc},{name:"Array",test:bt},{name:"Matrix",test:at},{name:"DenseMatrix",test:mc},{name:"SparseMatrix",test:Jo},{name:"Range",test:gc},{name:"Index",test:li},{name:"boolean",test:xc},{name:"ResultSet",test:vc},{name:"Help",test:_c},{name:"function",test:yc},{name:"Date",test:Mc},{name:"RegExp",test:Sc},{name:"null",test:wc},{name:"undefined",test:bc},{name:"AccessorNode",test:Ec},{name:"ArrayNode",test:Dc},{name:"AssignmentNode",test:Ac},{name:"BlockNode",test:Cc},{name:"ConditionalNode",test:Tc},{name:"ConstantNode",test:Rc},{name:"FunctionNode",test:Pc},{name:"FunctionAssignmentNode",test:Fc},{name:"IndexNode",test:Ic},{name:"Node",test:Nc},{name:"ObjectNode",test:Lc},{name:"OperatorNode",test:Bc},{name:"ParenthesisNode",test:Uc},{name:"RangeNode",test:Oc},{name:"RelationalNode",test:zc},{name:"SymbolNode",test:kc},{name:"Map",test:ai},{name:"Object",test:rr}]),s.addConversions([{from:"number",to:"BigNumber",convert:function(l){if(n||qc(l),Dv(l)>15)throw new TypeError("Cannot implicitly convert a number with >15 significant digits to BigNumber (value: "+l+"). Use function bignumber(x) to convert to BigNumber.");return new n(l)}},{from:"number",to:"Complex",convert:function(l){return r||Xc(l),new r(l,0)}},{from:"BigNumber",to:"Complex",convert:function(l){return r||Xc(l),new r(l.toNumber(),0)}},{from:"bigint",to:"number",convert:function(l){if(l>Number.MAX_SAFE_INTEGER)throw new TypeError("Cannot implicitly convert bigint to number: value exceeds the max safe integer value (value: "+l+")");return Number(l)}},{from:"bigint",to:"BigNumber",convert:function(l){return n||qc(l),new n(l.toString())}},{from:"bigint",to:"Fraction",convert:function(l){return o||Yc(l),new o(l)}},{from:"Fraction",to:"BigNumber",convert:function(l){throw new TypeError("Cannot implicitly convert a Fraction to BigNumber or vice versa. Use function bignumber(x) to convert to BigNumber or fraction(x) to convert to Fraction.")}},{from:"Fraction",to:"Complex",convert:function(l){return r||Xc(l),new r(l.valueOf(),0)}},{from:"number",to:"Fraction",convert:function(l){o||Yc(l);var u=new o(l);if(u.valueOf()!==l)throw new TypeError("Cannot implicitly convert a number to a Fraction when there will be a loss of precision (value: "+l+"). Use function fraction(x) to convert to Fraction.");return u}},{from:"string",to:"number",convert:function(l){var u=Number(l);if(isNaN(u))throw new Error('Cannot convert "'+l+'" to a number');return u}},{from:"string",to:"BigNumber",convert:function(l){n||qc(l);try{return new n(l)}catch{throw new Error('Cannot convert "'+l+'" to BigNumber')}}},{from:"string",to:"bigint",convert:function(l){try{return BigInt(l)}catch{throw new Error('Cannot convert "'+l+'" to BigInt')}}},{from:"string",to:"Fraction",convert:function(l){o||Yc(l);try{return new o(l)}catch{throw new Error('Cannot convert "'+l+'" to Fraction')}}},{from:"string",to:"Complex",convert:function(l){r||Xc(l);try{return new r(l)}catch{throw new Error('Cannot convert "'+l+'" to Complex')}}},{from:"boolean",to:"number",convert:function(l){return+l}},{from:"boolean",to:"BigNumber",convert:function(l){return n||qc(l),new n(+l)}},{from:"boolean",to:"bigint",convert:function(l){return BigInt(+l)}},{from:"boolean",to:"Fraction",convert:function(l){return o||Yc(l),new o(+l)}},{from:"boolean",to:"string",convert:function(l){return String(l)}},{from:"Array",to:"Matrix",convert:function(l){return i||kA(),new i(l)}},{from:"Matrix",to:"Array",convert:function(l){return l.valueOf()}}]),s.onMismatch=(a,l,u)=>{var c=s.createError(a,l,u);if(["wrongType","mismatch"].includes(c.data.category)&&l.length===1&&gr(l[0])&&u.some(h=>!h.params.includes(","))){var f=new TypeError("Function '".concat(a,"' doesn't apply to matrices. To call it ")+"elementwise on a matrix 'M', try 'map(M, ".concat(a,")'."));throw f.data=c.data,f}throw c},s.onMismatch=(a,l,u)=>{var c=s.createError(a,l,u);if(["wrongType","mismatch"].includes(c.data.category)&&l.length===1&&gr(l[0])&&u.some(h=>!h.params.includes(","))){var f=new TypeError("Function '".concat(a,"' doesn't apply to matrices. To call it ")+"elementwise on a matrix 'M', try 'map(M, ".concat(a,")'."));throw f.data=c.data,f}throw c},s});function qc(t){throw new Error("Cannot convert value ".concat(t," into a BigNumber: no class 'BigNumber' provided"))}function Xc(t){throw new Error("Cannot convert value ".concat(t," into a Complex number: no class 'Complex' provided"))}function kA(){throw new Error("Cannot convert array into a Matrix: no class 'DenseMatrix' provided")}function Yc(t){throw new Error("Cannot convert value ".concat(t," into a Fraction, no class 'Fraction' provided."))}/*!
 *  decimal.js v10.6.0
 *  An arbitrary-precision Decimal type for JavaScript.
 *  https://github.com/MikeMcl/decimal.js
 *  Copyright (c) 2025 Michael Mclaughlin <M8ch88l@gmail.com>
 *  MIT Licence
 */var jo=9e15,di=1e9,Wd="0123456789abcdef",Jc="2.3025850929940456840179914546843642076011014886287729760333279009675726096773524802359972050895982983419677840422862486334095254650828067566662873690987816894829072083255546808437998948262331985283935053089653777326288461633662222876982198867465436674744042432743651550489343149393914796194044002221051017141748003688084012647080685567743216228355220114804663715659121373450747856947683463616792101806445070648000277502684916746550586856935673420670581136429224554405758925724208241314695689016758940256776311356919292033376587141660230105703089634572075440370847469940168269282808481184289314848524948644871927809676271275775397027668605952496716674183485704422507197965004714951050492214776567636938662976979522110718264549734772662425709429322582798502585509785265383207606726317164309505995087807523710333101197857547331541421808427543863591778117054309827482385045648019095610299291824318237525357709750539565187697510374970888692180205189339507238539205144634197265287286965110862571492198849978748873771345686209167058",Kc="3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185950244594553469083026425223082533446850352619311881710100031378387528865875332083814206171776691473035982534904287554687311595628638823537875937519577818577805321712268066130019278766111959092164201989380952572010654858632789",qd={precision:20,rounding:4,modulo:1,toExpNeg:-7,toExpPos:21,minE:-jo,maxE:jo,crypto:!1},Fv,Lr,Ye=!0,jc="[DecimalError] ",hi=jc+"Invalid argument: ",Pv=jc+"Precision limit exceeded",Iv=jc+"crypto unavailable",Nv="[object Decimal]",rn=Math.floor,Vt=Math.pow,VA=/^0b([01]+(\.[01]*)?|\.[01]+)(p[+-]?\d+)?$/i,HA=/^0x([0-9a-f]+(\.[0-9a-f]*)?|\.[0-9a-f]+)(p[+-]?\d+)?$/i,GA=/^0o([0-7]+(\.[0-7]*)?|\.[0-7]+)(p[+-]?\d+)?$/i,Lv=/^(\d+(\.\d*)?|\.\d+)(e[+-]?\d+)?$/i,ir=1e7,Ge=7,WA=9007199254740991,qA=Jc.length-1,Xd=Kc.length-1,he={toStringTag:Nv};he.absoluteValue=he.abs=function(){var t=new this.constructor(this);return t.s<0&&(t.s=1),Ue(t)};he.ceil=function(){return Ue(new this.constructor(this),this.e+1,2)};he.clampedTo=he.clamp=function(t,e){var n,r=this,i=r.constructor;if(t=new i(t),e=new i(e),!t.s||!e.s)return new i(NaN);if(t.gt(e))throw Error(hi+e);return n=r.cmp(t),n<0?t:r.cmp(e)>0?e:new i(r)};he.comparedTo=he.cmp=function(t){var e,n,r,i,o=this,s=o.d,a=(t=new o.constructor(t)).d,l=o.s,u=t.s;if(!s||!a)return!l||!u?NaN:l!==u?l:s===a?0:!s^l<0?1:-1;if(!s[0]||!a[0])return s[0]?l:a[0]?-u:0;if(l!==u)return l;if(o.e!==t.e)return o.e>t.e^l<0?1:-1;for(r=s.length,i=a.length,e=0,n=r<i?r:i;e<n;++e)if(s[e]!==a[e])return s[e]>a[e]^l<0?1:-1;return r===i?0:r>i^l<0?1:-1};he.cosine=he.cos=function(){var t,e,n=this,r=n.constructor;return n.d?n.d[0]?(t=r.precision,e=r.rounding,r.precision=t+Math.max(n.e,n.sd())+Ge,r.rounding=1,n=XA(r,kv(r,n)),r.precision=t,r.rounding=e,Ue(Lr==2||Lr==3?n.neg():n,t,e,!0)):new r(1):new r(NaN)};he.cubeRoot=he.cbrt=function(){var t,e,n,r,i,o,s,a,l,u,c=this,f=c.constructor;if(!c.isFinite()||c.isZero())return new f(c);for(Ye=!1,o=c.s*Vt(c.s*c,1/3),!o||Math.abs(o)==1/0?(n=Qt(c.d),t=c.e,(o=(t-n.length+1)%3)&&(n+=o==1||o==-2?"0":"00"),o=Vt(n,1/3),t=rn((t+1)/3)-(t%3==(t<0?-1:2)),o==1/0?n="5e"+t:(n=o.toExponential(),n=n.slice(0,n.indexOf("e")+1)+t),r=new f(n),r.s=c.s):r=new f(o.toString()),s=(t=f.precision)+3;;)if(a=r,l=a.times(a).times(a),u=l.plus(c),r=Mt(u.plus(c).times(a),u.plus(l),s+2,1),Qt(a.d).slice(0,s)===(n=Qt(r.d)).slice(0,s))if(n=n.slice(s-3,s+1),n=="9999"||!i&&n=="4999"){if(!i&&(Ue(a,t+1,0),a.times(a).times(a).eq(c))){r=a;break}s+=4,i=1}else{(!+n||!+n.slice(1)&&n.charAt(0)=="5")&&(Ue(r,t+1,1),e=!r.times(r).times(r).eq(c));break}return Ye=!0,Ue(r,t,f.rounding,e)};he.decimalPlaces=he.dp=function(){var t,e=this.d,n=NaN;if(e){if(t=e.length-1,n=(t-rn(this.e/Ge))*Ge,t=e[t],t)for(;t%10==0;t/=10)n--;n<0&&(n=0)}return n};he.dividedBy=he.div=function(t){return Mt(this,new this.constructor(t))};he.dividedToIntegerBy=he.divToInt=function(t){var e=this,n=e.constructor;return Ue(Mt(e,new n(t),0,1,1),n.precision,n.rounding)};he.equals=he.eq=function(t){return this.cmp(t)===0};he.floor=function(){return Ue(new this.constructor(this),this.e+1,3)};he.greaterThan=he.gt=function(t){return this.cmp(t)>0};he.greaterThanOrEqualTo=he.gte=function(t){var e=this.cmp(t);return e==1||e===0};he.hyperbolicCosine=he.cosh=function(){var t,e,n,r,i,o=this,s=o.constructor,a=new s(1);if(!o.isFinite())return new s(o.s?1/0:NaN);if(o.isZero())return a;n=s.precision,r=s.rounding,s.precision=n+Math.max(o.e,o.sd())+4,s.rounding=1,i=o.d.length,i<32?(t=Math.ceil(i/3),e=(1/tf(4,t)).toString()):(t=16,e="2.3283064365386962890625e-10"),o=es(s,1,o.times(e),new s(1),!0);for(var l,u=t,c=new s(8);u--;)l=o.times(o),o=a.minus(l.times(c.minus(l.times(c))));return Ue(o,s.precision=n,s.rounding=r,!0)};he.hyperbolicSine=he.sinh=function(){var t,e,n,r,i=this,o=i.constructor;if(!i.isFinite()||i.isZero())return new o(i);if(e=o.precision,n=o.rounding,o.precision=e+Math.max(i.e,i.sd())+4,o.rounding=1,r=i.d.length,r<3)i=es(o,2,i,i,!0);else{t=1.4*Math.sqrt(r),t=t>16?16:t|0,i=i.times(1/tf(5,t)),i=es(o,2,i,i,!0);for(var s,a=new o(5),l=new o(16),u=new o(20);t--;)s=i.times(i),i=i.times(a.plus(s.times(l.times(s).plus(u))))}return o.precision=e,o.rounding=n,Ue(i,e,n,!0)};he.hyperbolicTangent=he.tanh=function(){var t,e,n=this,r=n.constructor;return n.isFinite()?n.isZero()?new r(n):(t=r.precision,e=r.rounding,r.precision=t+7,r.rounding=1,Mt(n.sinh(),n.cosh(),r.precision=t,r.rounding=e)):new r(n.s)};he.inverseCosine=he.acos=function(){var t=this,e=t.constructor,n=t.abs().cmp(1),r=e.precision,i=e.rounding;return n!==-1?n===0?t.isNeg()?xr(e,r,i):new e(0):new e(NaN):t.isZero()?xr(e,r+4,i).times(.5):(e.precision=r+6,e.rounding=1,t=new e(1).minus(t).div(t.plus(1)).sqrt().atan(),e.precision=r,e.rounding=i,t.times(2))};he.inverseHyperbolicCosine=he.acosh=function(){var t,e,n=this,r=n.constructor;return n.lte(1)?new r(n.eq(1)?0:NaN):n.isFinite()?(t=r.precision,e=r.rounding,r.precision=t+Math.max(Math.abs(n.e),n.sd())+4,r.rounding=1,Ye=!1,n=n.times(n).minus(1).sqrt().plus(n),Ye=!0,r.precision=t,r.rounding=e,n.ln()):new r(n)};he.inverseHyperbolicSine=he.asinh=function(){var t,e,n=this,r=n.constructor;return!n.isFinite()||n.isZero()?new r(n):(t=r.precision,e=r.rounding,r.precision=t+2*Math.max(Math.abs(n.e),n.sd())+6,r.rounding=1,Ye=!1,n=n.times(n).plus(1).sqrt().plus(n),Ye=!0,r.precision=t,r.rounding=e,n.ln())};he.inverseHyperbolicTangent=he.atanh=function(){var t,e,n,r,i=this,o=i.constructor;return i.isFinite()?i.e>=0?new o(i.abs().eq(1)?i.s/0:i.isZero()?i:NaN):(t=o.precision,e=o.rounding,r=i.sd(),Math.max(r,t)<2*-i.e-1?Ue(new o(i),t,e,!0):(o.precision=n=r-i.e,i=Mt(i.plus(1),new o(1).minus(i),n+t,1),o.precision=t+4,o.rounding=1,i=i.ln(),o.precision=t,o.rounding=e,i.times(.5))):new o(NaN)};he.inverseSine=he.asin=function(){var t,e,n,r,i=this,o=i.constructor;return i.isZero()?new o(i):(e=i.abs().cmp(1),n=o.precision,r=o.rounding,e!==-1?e===0?(t=xr(o,n+4,r).times(.5),t.s=i.s,t):new o(NaN):(o.precision=n+6,o.rounding=1,i=i.div(new o(1).minus(i.times(i)).sqrt().plus(1)).atan(),o.precision=n,o.rounding=r,i.times(2)))};he.inverseTangent=he.atan=function(){var t,e,n,r,i,o,s,a,l,u=this,c=u.constructor,f=c.precision,h=c.rounding;if(u.isFinite()){if(u.isZero())return new c(u);if(u.abs().eq(1)&&f+4<=Xd)return s=xr(c,f+4,h).times(.25),s.s=u.s,s}else{if(!u.s)return new c(NaN);if(f+4<=Xd)return s=xr(c,f+4,h).times(.5),s.s=u.s,s}for(c.precision=a=f+10,c.rounding=1,n=Math.min(28,a/Ge+2|0),t=n;t;--t)u=u.div(u.times(u).plus(1).sqrt().plus(1));for(Ye=!1,e=Math.ceil(a/Ge),r=1,l=u.times(u),s=new c(u),i=u;t!==-1;)if(i=i.times(l),o=s.minus(i.div(r+=2)),i=i.times(l),s=o.plus(i.div(r+=2)),s.d[e]!==void 0)for(t=e;s.d[t]===o.d[t]&&t--;);return n&&(s=s.times(2<<n-1)),Ye=!0,Ue(s,c.precision=f,c.rounding=h,!0)};he.isFinite=function(){return!!this.d};he.isInteger=he.isInt=function(){return!!this.d&&rn(this.e/Ge)>this.d.length-2};he.isNaN=function(){return!this.s};he.isNegative=he.isNeg=function(){return this.s<0};he.isPositive=he.isPos=function(){return this.s>0};he.isZero=function(){return!!this.d&&this.d[0]===0};he.lessThan=he.lt=function(t){return this.cmp(t)<0};he.lessThanOrEqualTo=he.lte=function(t){return this.cmp(t)<1};he.logarithm=he.log=function(t){var e,n,r,i,o,s,a,l,u=this,c=u.constructor,f=c.precision,h=c.rounding,d=5;if(t==null)t=new c(10),e=!0;else{if(t=new c(t),n=t.d,t.s<0||!n||!n[0]||t.eq(1))return new c(NaN);e=t.eq(10)}if(n=u.d,u.s<0||!n||!n[0]||u.eq(1))return new c(n&&!n[0]?-1/0:u.s!=1?NaN:n?0:1/0);if(e)if(n.length>1)o=!0;else{for(i=n[0];i%10===0;)i/=10;o=i!==1}if(Ye=!1,a=f+d,s=fi(u,a),r=e?Qc(c,a+10):fi(t,a),l=Mt(s,r,a,1),va(l.d,i=f,h))do if(a+=10,s=fi(u,a),r=e?Qc(c,a+10):fi(t,a),l=Mt(s,r,a,1),!o){+Qt(l.d).slice(i+1,i+15)+1==1e14&&(l=Ue(l,f+1,0));break}while(va(l.d,i+=10,h));return Ye=!0,Ue(l,f,h)};he.minus=he.sub=function(t){var e,n,r,i,o,s,a,l,u,c,f,h,d=this,x=d.constructor;if(t=new x(t),!d.d||!t.d)return!d.s||!t.s?t=new x(NaN):d.d?t.s=-t.s:t=new x(t.d||d.s!==t.s?d:NaN),t;if(d.s!=t.s)return t.s=-t.s,d.plus(t);if(u=d.d,h=t.d,a=x.precision,l=x.rounding,!u[0]||!h[0]){if(h[0])t.s=-t.s;else if(u[0])t=new x(d);else return new x(l===3?-0:0);return Ye?Ue(t,a,l):t}if(n=rn(t.e/Ge),c=rn(d.e/Ge),u=u.slice(),o=c-n,o){for(f=o<0,f?(e=u,o=-o,s=h.length):(e=h,n=c,s=u.length),r=Math.max(Math.ceil(a/Ge),s)+2,o>r&&(o=r,e.length=1),e.reverse(),r=o;r--;)e.push(0);e.reverse()}else{for(r=u.length,s=h.length,f=r<s,f&&(s=r),r=0;r<s;r++)if(u[r]!=h[r]){f=u[r]<h[r];break}o=0}for(f&&(e=u,u=h,h=e,t.s=-t.s),s=u.length,r=h.length-s;r>0;--r)u[s++]=0;for(r=h.length;r>o;){if(u[--r]<h[r]){for(i=r;i&&u[--i]===0;)u[i]=ir-1;--u[i],u[r]+=ir}u[r]-=h[r]}for(;u[--s]===0;)u.pop();for(;u[0]===0;u.shift())--n;return u[0]?(t.d=u,t.e=ef(u,n),Ye?Ue(t,a,l):t):new x(l===3?-0:0)};he.modulo=he.mod=function(t){var e,n=this,r=n.constructor;return t=new r(t),!n.d||!t.s||t.d&&!t.d[0]?new r(NaN):!t.d||n.d&&!n.d[0]?Ue(new r(n),r.precision,r.rounding):(Ye=!1,r.modulo==9?(e=Mt(n,t.abs(),0,3,1),e.s*=t.s):e=Mt(n,t,0,r.modulo,1),e=e.times(t),Ye=!0,n.minus(e))};he.naturalExponential=he.exp=function(){return Yd(this)};he.naturalLogarithm=he.ln=function(){return fi(this)};he.negated=he.neg=function(){var t=new this.constructor(this);return t.s=-t.s,Ue(t)};he.plus=he.add=function(t){var e,n,r,i,o,s,a,l,u,c,f=this,h=f.constructor;if(t=new h(t),!f.d||!t.d)return!f.s||!t.s?t=new h(NaN):f.d||(t=new h(t.d||f.s===t.s?f:NaN)),t;if(f.s!=t.s)return t.s=-t.s,f.minus(t);if(u=f.d,c=t.d,a=h.precision,l=h.rounding,!u[0]||!c[0])return c[0]||(t=new h(f)),Ye?Ue(t,a,l):t;if(o=rn(f.e/Ge),r=rn(t.e/Ge),u=u.slice(),i=o-r,i){for(i<0?(n=u,i=-i,s=c.length):(n=c,r=o,s=u.length),o=Math.ceil(a/Ge),s=o>s?o+1:s+1,i>s&&(i=s,n.length=1),n.reverse();i--;)n.push(0);n.reverse()}for(s=u.length,i=c.length,s-i<0&&(i=s,n=c,c=u,u=n),e=0;i;)e=(u[--i]=u[i]+c[i]+e)/ir|0,u[i]%=ir;for(e&&(u.unshift(e),++r),s=u.length;u[--s]==0;)u.pop();return t.d=u,t.e=ef(u,r),Ye?Ue(t,a,l):t};he.precision=he.sd=function(t){var e,n=this;if(t!==void 0&&t!==!!t&&t!==1&&t!==0)throw Error(hi+t);return n.d?(e=Bv(n.d),t&&n.e+1>e&&(e=n.e+1)):e=NaN,e};he.round=function(){var t=this,e=t.constructor;return Ue(new e(t),t.e+1,e.rounding)};he.sine=he.sin=function(){var t,e,n=this,r=n.constructor;return n.isFinite()?n.isZero()?new r(n):(t=r.precision,e=r.rounding,r.precision=t+Math.max(n.e,n.sd())+Ge,r.rounding=1,n=ZA(r,kv(r,n)),r.precision=t,r.rounding=e,Ue(Lr>2?n.neg():n,t,e,!0)):new r(NaN)};he.squareRoot=he.sqrt=function(){var t,e,n,r,i,o,s=this,a=s.d,l=s.e,u=s.s,c=s.constructor;if(u!==1||!a||!a[0])return new c(!u||u<0&&(!a||a[0])?NaN:a?s:1/0);for(Ye=!1,u=Math.sqrt(+s),u==0||u==1/0?(e=Qt(a),(e.length+l)%2==0&&(e+="0"),u=Math.sqrt(e),l=rn((l+1)/2)-(l<0||l%2),u==1/0?e="5e"+l:(e=u.toExponential(),e=e.slice(0,e.indexOf("e")+1)+l),r=new c(e)):r=new c(u.toString()),n=(l=c.precision)+3;;)if(o=r,r=o.plus(Mt(s,o,n+2,1)).times(.5),Qt(o.d).slice(0,n)===(e=Qt(r.d)).slice(0,n))if(e=e.slice(n-3,n+1),e=="9999"||!i&&e=="4999"){if(!i&&(Ue(o,l+1,0),o.times(o).eq(s))){r=o;break}n+=4,i=1}else{(!+e||!+e.slice(1)&&e.charAt(0)=="5")&&(Ue(r,l+1,1),t=!r.times(r).eq(s));break}return Ye=!0,Ue(r,l,c.rounding,t)};he.tangent=he.tan=function(){var t,e,n=this,r=n.constructor;return n.isFinite()?n.isZero()?new r(n):(t=r.precision,e=r.rounding,r.precision=t+10,r.rounding=1,n=n.sin(),n.s=1,n=Mt(n,new r(1).minus(n.times(n)).sqrt(),t+10,0),r.precision=t,r.rounding=e,Ue(Lr==2||Lr==4?n.neg():n,t,e,!0)):new r(NaN)};he.times=he.mul=function(t){var e,n,r,i,o,s,a,l,u,c=this,f=c.constructor,h=c.d,d=(t=new f(t)).d;if(t.s*=c.s,!h||!h[0]||!d||!d[0])return new f(!t.s||h&&!h[0]&&!d||d&&!d[0]&&!h?NaN:!h||!d?t.s/0:t.s*0);for(n=rn(c.e/Ge)+rn(t.e/Ge),l=h.length,u=d.length,l<u&&(o=h,h=d,d=o,s=l,l=u,u=s),o=[],s=l+u,r=s;r--;)o.push(0);for(r=u;--r>=0;){for(e=0,i=l+r;i>r;)a=o[i]+d[r]*h[i-r-1]+e,o[i--]=a%ir|0,e=a/ir|0;o[i]=(o[i]+e)%ir|0}for(;!o[--s];)o.pop();return e?++n:o.shift(),t.d=o,t.e=ef(o,n),Ye?Ue(t,f.precision,f.rounding):t};he.toBinary=function(t,e){return Zd(this,2,t,e)};he.toDecimalPlaces=he.toDP=function(t,e){var n=this,r=n.constructor;return n=new r(n),t===void 0?n:(vn(t,0,di),e===void 0?e=r.rounding:vn(e,0,8),Ue(n,t+n.e+1,e))};he.toExponential=function(t,e){var n,r=this,i=r.constructor;return t===void 0?n=vr(r,!0):(vn(t,0,di),e===void 0?e=i.rounding:vn(e,0,8),r=Ue(new i(r),t+1,e),n=vr(r,!0,t+1)),r.isNeg()&&!r.isZero()?"-"+n:n};he.toFixed=function(t,e){var n,r,i=this,o=i.constructor;return t===void 0?n=vr(i):(vn(t,0,di),e===void 0?e=o.rounding:vn(e,0,8),r=Ue(new o(i),t+i.e+1,e),n=vr(r,!1,t+r.e+1)),i.isNeg()&&!i.isZero()?"-"+n:n};he.toFraction=function(t){var e,n,r,i,o,s,a,l,u,c,f,h,d=this,x=d.d,p=d.constructor;if(!x)return new p(d);if(u=n=new p(1),r=l=new p(0),e=new p(r),o=e.e=Bv(x)-d.e-1,s=o%Ge,e.d[0]=Vt(10,s<0?Ge+s:s),t==null)t=o>0?e:u;else{if(a=new p(t),!a.isInt()||a.lt(u))throw Error(hi+a);t=a.gt(e)?o>0?e:u:a}for(Ye=!1,a=new p(Qt(x)),c=p.precision,p.precision=o=x.length*Ge*2;f=Mt(a,e,0,1,1),i=n.plus(f.times(r)),i.cmp(t)!=1;)n=r,r=i,i=u,u=l.plus(f.times(i)),l=i,i=e,e=a.minus(f.times(i)),a=i;return i=Mt(t.minus(n),r,0,1,1),l=l.plus(i.times(u)),n=n.plus(i.times(r)),l.s=u.s=d.s,h=Mt(u,r,o,1).minus(d).abs().cmp(Mt(l,n,o,1).minus(d).abs())<1?[u,r]:[l,n],p.precision=c,Ye=!0,h};he.toHexadecimal=he.toHex=function(t,e){return Zd(this,16,t,e)};he.toNearest=function(t,e){var n=this,r=n.constructor;if(n=new r(n),t==null){if(!n.d)return n;t=new r(1),e=r.rounding}else{if(t=new r(t),e===void 0?e=r.rounding:vn(e,0,8),!n.d)return t.s?n:t;if(!t.d)return t.s&&(t.s=n.s),t}return t.d[0]?(Ye=!1,n=Mt(n,t,0,e,1).times(t),Ye=!0,Ue(n)):(t.s=n.s,n=t),n};he.toNumber=function(){return+this};he.toOctal=function(t,e){return Zd(this,8,t,e)};he.toPower=he.pow=function(t){var e,n,r,i,o,s,a=this,l=a.constructor,u=+(t=new l(t));if(!a.d||!t.d||!a.d[0]||!t.d[0])return new l(Vt(+a,u));if(a=new l(a),a.eq(1))return a;if(r=l.precision,o=l.rounding,t.eq(1))return Ue(a,r,o);if(e=rn(t.e/Ge),e>=t.d.length-1&&(n=u<0?-u:u)<=WA)return i=Uv(l,a,n,r),t.s<0?new l(1).div(i):Ue(i,r,o);if(s=a.s,s<0){if(e<t.d.length-1)return new l(NaN);if((t.d[e]&1)==0&&(s=1),a.e==0&&a.d[0]==1&&a.d.length==1)return a.s=s,a}return n=Vt(+a,u),e=n==0||!isFinite(n)?rn(u*(Math.log("0."+Qt(a.d))/Math.LN10+a.e+1)):new l(n+"").e,e>l.maxE+1||e<l.minE-1?new l(e>0?s/0:0):(Ye=!1,l.rounding=a.s=1,n=Math.min(12,(e+"").length),i=Yd(t.times(fi(a,r+n)),r),i.d&&(i=Ue(i,r+5,1),va(i.d,r,o)&&(e=r+10,i=Ue(Yd(t.times(fi(a,e+n)),e),e+5,1),+Qt(i.d).slice(r+1,r+15)+1==1e14&&(i=Ue(i,r+1,0)))),i.s=s,Ye=!0,l.rounding=o,Ue(i,r,o))};he.toPrecision=function(t,e){var n,r=this,i=r.constructor;return t===void 0?n=vr(r,r.e<=i.toExpNeg||r.e>=i.toExpPos):(vn(t,1,di),e===void 0?e=i.rounding:vn(e,0,8),r=Ue(new i(r),t,e),n=vr(r,t<=r.e||r.e<=i.toExpNeg,t)),r.isNeg()&&!r.isZero()?"-"+n:n};he.toSignificantDigits=he.toSD=function(t,e){var n=this,r=n.constructor;return t===void 0?(t=r.precision,e=r.rounding):(vn(t,1,di),e===void 0?e=r.rounding:vn(e,0,8)),Ue(new r(n),t,e)};he.toString=function(){var t=this,e=t.constructor,n=vr(t,t.e<=e.toExpNeg||t.e>=e.toExpPos);return t.isNeg()&&!t.isZero()?"-"+n:n};he.truncated=he.trunc=function(){return Ue(new this.constructor(this),this.e+1,1)};he.valueOf=he.toJSON=function(){var t=this,e=t.constructor,n=vr(t,t.e<=e.toExpNeg||t.e>=e.toExpPos);return t.isNeg()?"-"+n:n};function Qt(t){var e,n,r,i=t.length-1,o="",s=t[0];if(i>0){for(o+=s,e=1;e<i;e++)r=t[e]+"",n=Ge-r.length,n&&(o+=ci(n)),o+=r;s=t[e],r=s+"",n=Ge-r.length,n&&(o+=ci(n))}else if(s===0)return"0";for(;s%10===0;)s/=10;return o+s}function vn(t,e,n){if(t!==~~t||t<e||t>n)throw Error(hi+t)}function va(t,e,n,r){var i,o,s,a;for(o=t[0];o>=10;o/=10)--e;return--e<0?(e+=Ge,i=0):(i=Math.ceil((e+1)/Ge),e%=Ge),o=Vt(10,Ge-e),a=t[i]%o|0,r==null?e<3?(e==0?a=a/100|0:e==1&&(a=a/10|0),s=n<4&&a==99999||n>3&&a==49999||a==5e4||a==0):s=(n<4&&a+1==o||n>3&&a+1==o/2)&&(t[i+1]/o/100|0)==Vt(10,e-2)-1||(a==o/2||a==0)&&(t[i+1]/o/100|0)==0:e<4?(e==0?a=a/1e3|0:e==1?a=a/100|0:e==2&&(a=a/10|0),s=(r||n<4)&&a==9999||!r&&n>3&&a==4999):s=((r||n<4)&&a+1==o||!r&&n>3&&a+1==o/2)&&(t[i+1]/o/1e3|0)==Vt(10,e-3)-1,s}function Zc(t,e,n){for(var r,i=[0],o,s=0,a=t.length;s<a;){for(o=i.length;o--;)i[o]*=e;for(i[0]+=Wd.indexOf(t.charAt(s++)),r=0;r<i.length;r++)i[r]>n-1&&(i[r+1]===void 0&&(i[r+1]=0),i[r+1]+=i[r]/n|0,i[r]%=n)}return i.reverse()}function XA(t,e){var n,r,i;if(e.isZero())return e;r=e.d.length,r<32?(n=Math.ceil(r/3),i=(1/tf(4,n)).toString()):(n=16,i="2.3283064365386962890625e-10"),t.precision+=n,e=es(t,1,e.times(i),new t(1));for(var o=n;o--;){var s=e.times(e);e=s.times(s).minus(s).times(8).plus(1)}return t.precision-=n,e}var Mt=(function(){function t(r,i,o){var s,a=0,l=r.length;for(r=r.slice();l--;)s=r[l]*i+a,r[l]=s%o|0,a=s/o|0;return a&&r.unshift(a),r}function e(r,i,o,s){var a,l;if(o!=s)l=o>s?1:-1;else for(a=l=0;a<o;a++)if(r[a]!=i[a]){l=r[a]>i[a]?1:-1;break}return l}function n(r,i,o,s){for(var a=0;o--;)r[o]-=a,a=r[o]<i[o]?1:0,r[o]=a*s+r[o]-i[o];for(;!r[0]&&r.length>1;)r.shift()}return function(r,i,o,s,a,l){var u,c,f,h,d,x,p,g,m,b,v,_,M,y,E,D,S,w,C,F,O=r.constructor,U=r.s==i.s?1:-1,z=r.d,B=i.d;if(!z||!z[0]||!B||!B[0])return new O(!r.s||!i.s||(z?B&&z[0]==B[0]:!B)?NaN:z&&z[0]==0||!B?U*0:U/0);for(l?(d=1,c=r.e-i.e):(l=ir,d=Ge,c=rn(r.e/d)-rn(i.e/d)),C=B.length,S=z.length,m=new O(U),b=m.d=[],f=0;B[f]==(z[f]||0);f++);if(B[f]>(z[f]||0)&&c--,o==null?(y=o=O.precision,s=O.rounding):a?y=o+(r.e-i.e)+1:y=o,y<0)b.push(1),x=!0;else{if(y=y/d+2|0,f=0,C==1){for(h=0,B=B[0],y++;(f<S||h)&&y--;f++)E=h*l+(z[f]||0),b[f]=E/B|0,h=E%B|0;x=h||f<S}else{for(h=l/(B[0]+1)|0,h>1&&(B=t(B,h,l),z=t(z,h,l),C=B.length,S=z.length),D=C,v=z.slice(0,C),_=v.length;_<C;)v[_++]=0;F=B.slice(),F.unshift(0),w=B[0],B[1]>=l/2&&++w;do h=0,u=e(B,v,C,_),u<0?(M=v[0],C!=_&&(M=M*l+(v[1]||0)),h=M/w|0,h>1?(h>=l&&(h=l-1),p=t(B,h,l),g=p.length,_=v.length,u=e(p,v,g,_),u==1&&(h--,n(p,C<g?F:B,g,l))):(h==0&&(u=h=1),p=B.slice()),g=p.length,g<_&&p.unshift(0),n(v,p,_,l),u==-1&&(_=v.length,u=e(B,v,C,_),u<1&&(h++,n(v,C<_?F:B,_,l))),_=v.length):u===0&&(h++,v=[0]),b[f++]=h,u&&v[0]?v[_++]=z[D]||0:(v=[z[D]],_=1);while((D++<S||v[0]!==void 0)&&y--);x=v[0]!==void 0}b[0]||b.shift()}if(d==1)m.e=c,Fv=x;else{for(f=1,h=b[0];h>=10;h/=10)f++;m.e=f+c*d-1,Ue(m,a?o+m.e+1:o,s,x)}return m}})();function Ue(t,e,n,r){var i,o,s,a,l,u,c,f,h,d=t.constructor;e:if(e!=null){if(f=t.d,!f)return t;for(i=1,a=f[0];a>=10;a/=10)i++;if(o=e-i,o<0)o+=Ge,s=e,c=f[h=0],l=c/Vt(10,i-s-1)%10|0;else if(h=Math.ceil((o+1)/Ge),a=f.length,h>=a)if(r){for(;a++<=h;)f.push(0);c=l=0,i=1,o%=Ge,s=o-Ge+1}else break e;else{for(c=a=f[h],i=1;a>=10;a/=10)i++;o%=Ge,s=o-Ge+i,l=s<0?0:c/Vt(10,i-s-1)%10|0}if(r=r||e<0||f[h+1]!==void 0||(s<0?c:c%Vt(10,i-s-1)),u=n<4?(l||r)&&(n==0||n==(t.s<0?3:2)):l>5||l==5&&(n==4||r||n==6&&(o>0?s>0?c/Vt(10,i-s):0:f[h-1])%10&1||n==(t.s<0?8:7)),e<1||!f[0])return f.length=0,u?(e-=t.e+1,f[0]=Vt(10,(Ge-e%Ge)%Ge),t.e=-e||0):f[0]=t.e=0,t;if(o==0?(f.length=h,a=1,h--):(f.length=h+1,a=Vt(10,Ge-o),f[h]=s>0?(c/Vt(10,i-s)%Vt(10,s)|0)*a:0),u)for(;;)if(h==0){for(o=1,s=f[0];s>=10;s/=10)o++;for(s=f[0]+=a,a=1;s>=10;s/=10)a++;o!=a&&(t.e++,f[0]==ir&&(f[0]=1));break}else{if(f[h]+=a,f[h]!=ir)break;f[h--]=0,a=1}for(o=f.length;f[--o]===0;)f.pop()}return Ye&&(t.e>d.maxE?(t.d=null,t.e=NaN):t.e<d.minE&&(t.e=0,t.d=[0])),t}function vr(t,e,n){if(!t.isFinite())return zv(t);var r,i=t.e,o=Qt(t.d),s=o.length;return e?(n&&(r=n-s)>0?o=o.charAt(0)+"."+o.slice(1)+ci(r):s>1&&(o=o.charAt(0)+"."+o.slice(1)),o=o+(t.e<0?"e":"e+")+t.e):i<0?(o="0."+ci(-i-1)+o,n&&(r=n-s)>0&&(o+=ci(r))):i>=s?(o+=ci(i+1-s),n&&(r=n-i-1)>0&&(o=o+"."+ci(r))):((r=i+1)<s&&(o=o.slice(0,r)+"."+o.slice(r)),n&&(r=n-s)>0&&(i+1===s&&(o+="."),o+=ci(r))),o}function ef(t,e){var n=t[0];for(e*=Ge;n>=10;n/=10)e++;return e}function Qc(t,e,n){if(e>qA)throw Ye=!0,n&&(t.precision=n),Error(Pv);return Ue(new t(Jc),e,1,!0)}function xr(t,e,n){if(e>Xd)throw Error(Pv);return Ue(new t(Kc),e,n,!0)}function Bv(t){var e=t.length-1,n=e*Ge+1;if(e=t[e],e){for(;e%10==0;e/=10)n--;for(e=t[0];e>=10;e/=10)n++}return n}function ci(t){for(var e="";t--;)e+="0";return e}function Uv(t,e,n,r){var i,o=new t(1),s=Math.ceil(r/Ge+4);for(Ye=!1;;){if(n%2&&(o=o.times(e),Tv(o.d,s)&&(i=!0)),n=rn(n/2),n===0){n=o.d.length-1,i&&o.d[n]===0&&++o.d[n];break}e=e.times(e),Tv(e.d,s)}return Ye=!0,o}function Cv(t){return t.d[t.d.length-1]&1}function Ov(t,e,n){for(var r,i,o=new t(e[0]),s=0;++s<e.length;){if(i=new t(e[s]),!i.s){o=i;break}r=o.cmp(i),(r===n||r===0&&o.s===n)&&(o=i)}return o}function Yd(t,e){var n,r,i,o,s,a,l,u=0,c=0,f=0,h=t.constructor,d=h.rounding,x=h.precision;if(!t.d||!t.d[0]||t.e>17)return new h(t.d?t.d[0]?t.s<0?0:1/0:1:t.s?t.s<0?0:t:NaN);for(e==null?(Ye=!1,l=x):l=e,a=new h(.03125);t.e>-2;)t=t.times(a),f+=5;for(r=Math.log(Vt(2,f))/Math.LN10*2+5|0,l+=r,n=o=s=new h(1),h.precision=l;;){if(o=Ue(o.times(t),l,1),n=n.times(++c),a=s.plus(Mt(o,n,l,1)),Qt(a.d).slice(0,l)===Qt(s.d).slice(0,l)){for(i=f;i--;)s=Ue(s.times(s),l,1);if(e==null)if(u<3&&va(s.d,l-r,d,u))h.precision=l+=10,n=o=a=new h(1),c=0,u++;else return Ue(s,h.precision=x,d,Ye=!0);else return h.precision=x,s}s=a}}function fi(t,e){var n,r,i,o,s,a,l,u,c,f,h,d=1,x=10,p=t,g=p.d,m=p.constructor,b=m.rounding,v=m.precision;if(p.s<0||!g||!g[0]||!p.e&&g[0]==1&&g.length==1)return new m(g&&!g[0]?-1/0:p.s!=1?NaN:g?0:p);if(e==null?(Ye=!1,c=v):c=e,m.precision=c+=x,n=Qt(g),r=n.charAt(0),Math.abs(o=p.e)<15e14){for(;r<7&&r!=1||r==1&&n.charAt(1)>3;)p=p.times(t),n=Qt(p.d),r=n.charAt(0),d++;o=p.e,r>1?(p=new m("0."+n),o++):p=new m(r+"."+n.slice(1))}else return u=Qc(m,c+2,v).times(o+""),p=fi(new m(r+"."+n.slice(1)),c-x).plus(u),m.precision=v,e==null?Ue(p,v,b,Ye=!0):p;for(f=p,l=s=p=Mt(p.minus(1),p.plus(1),c,1),h=Ue(p.times(p),c,1),i=3;;){if(s=Ue(s.times(h),c,1),u=l.plus(Mt(s,new m(i),c,1)),Qt(u.d).slice(0,c)===Qt(l.d).slice(0,c))if(l=l.times(2),o!==0&&(l=l.plus(Qc(m,c+2,v).times(o+""))),l=Mt(l,new m(d),c,1),e==null)if(va(l.d,c-x,b,a))m.precision=c+=x,u=s=p=Mt(f.minus(1),f.plus(1),c,1),h=Ue(p.times(p),c,1),i=a=1;else return Ue(l,m.precision=v,b,Ye=!0);else return m.precision=v,l;l=u,i+=2}}function zv(t){return String(t.s*t.s/0)}function $c(t,e){var n,r,i;for((n=e.indexOf("."))>-1&&(e=e.replace(".","")),(r=e.search(/e/i))>0?(n<0&&(n=r),n+=+e.slice(r+1),e=e.substring(0,r)):n<0&&(n=e.length),r=0;e.charCodeAt(r)===48;r++);for(i=e.length;e.charCodeAt(i-1)===48;--i);if(e=e.slice(r,i),e){if(i-=r,t.e=n=n-r-1,t.d=[],r=(n+1)%Ge,n<0&&(r+=Ge),r<i){for(r&&t.d.push(+e.slice(0,r)),i-=Ge;r<i;)t.d.push(+e.slice(r,r+=Ge));e=e.slice(r),r=Ge-e.length}else r-=i;for(;r--;)e+="0";t.d.push(+e),Ye&&(t.e>t.constructor.maxE?(t.d=null,t.e=NaN):t.e<t.constructor.minE&&(t.e=0,t.d=[0]))}else t.e=0,t.d=[0];return t}function YA(t,e){var n,r,i,o,s,a,l,u,c;if(e.indexOf("_")>-1){if(e=e.replace(/(\d)_(?=\d)/g,"$1"),Lv.test(e))return $c(t,e)}else if(e==="Infinity"||e==="NaN")return+e||(t.s=NaN),t.e=NaN,t.d=null,t;if(HA.test(e))n=16,e=e.toLowerCase();else if(VA.test(e))n=2;else if(GA.test(e))n=8;else throw Error(hi+e);for(o=e.search(/p/i),o>0?(l=+e.slice(o+1),e=e.substring(2,o)):e=e.slice(2),o=e.indexOf("."),s=o>=0,r=t.constructor,s&&(e=e.replace(".",""),a=e.length,o=a-o,i=Uv(r,new r(n),o,o*2)),u=Zc(e,n,ir),c=u.length-1,o=c;u[o]===0;--o)u.pop();return o<0?new r(t.s*0):(t.e=ef(u,c),t.d=u,Ye=!1,s&&(t=Mt(t,i,a*4)),l&&(t=t.times(Math.abs(l)<54?Vt(2,l):_a.pow(2,l))),Ye=!0,t)}function ZA(t,e){var n,r=e.d.length;if(r<3)return e.isZero()?e:es(t,2,e,e);n=1.4*Math.sqrt(r),n=n>16?16:n|0,e=e.times(1/tf(5,n)),e=es(t,2,e,e);for(var i,o=new t(5),s=new t(16),a=new t(20);n--;)i=e.times(e),e=e.times(o.plus(i.times(s.times(i).minus(a))));return e}function es(t,e,n,r,i){var o,s,a,l,u=1,c=t.precision,f=Math.ceil(c/Ge);for(Ye=!1,l=n.times(n),a=new t(r);;){if(s=Mt(a.times(l),new t(e++*e++),c,1),a=i?r.plus(s):r.minus(s),r=Mt(s.times(l),new t(e++*e++),c,1),s=a.plus(r),s.d[f]!==void 0){for(o=f;s.d[o]===a.d[o]&&o--;);if(o==-1)break}o=a,a=r,r=s,s=o,u++}return Ye=!0,s.d.length=f+1,s}function tf(t,e){for(var n=t;--e;)n*=t;return n}function kv(t,e){var n,r=e.s<0,i=xr(t,t.precision,1),o=i.times(.5);if(e=e.abs(),e.lte(o))return Lr=r?4:1,e;if(n=e.divToInt(i),n.isZero())Lr=r?3:2;else{if(e=e.minus(n.times(i)),e.lte(o))return Lr=Cv(n)?r?2:3:r?4:1,e;Lr=Cv(n)?r?1:4:r?3:2}return e.minus(i).abs()}function Zd(t,e,n,r){var i,o,s,a,l,u,c,f,h,d=t.constructor,x=n!==void 0;if(x?(vn(n,1,di),r===void 0?r=d.rounding:vn(r,0,8)):(n=d.precision,r=d.rounding),!t.isFinite())c=zv(t);else{for(c=vr(t),s=c.indexOf("."),x?(i=2,e==16?n=n*4-3:e==8&&(n=n*3-2)):i=e,s>=0&&(c=c.replace(".",""),h=new d(1),h.e=c.length-s,h.d=Zc(vr(h),10,i),h.e=h.d.length),f=Zc(c,10,i),o=l=f.length;f[--l]==0;)f.pop();if(!f[0])c=x?"0p+0":"0";else{if(s<0?o--:(t=new d(t),t.d=f,t.e=o,t=Mt(t,h,n,r,0,i),f=t.d,o=t.e,u=Fv),s=f[n],a=i/2,u=u||f[n+1]!==void 0,u=r<4?(s!==void 0||u)&&(r===0||r===(t.s<0?3:2)):s>a||s===a&&(r===4||u||r===6&&f[n-1]&1||r===(t.s<0?8:7)),f.length=n,u)for(;++f[--n]>i-1;)f[n]=0,n||(++o,f.unshift(1));for(l=f.length;!f[l-1];--l);for(s=0,c="";s<l;s++)c+=Wd.charAt(f[s]);if(x){if(l>1)if(e==16||e==8){for(s=e==16?4:3,--l;l%s;l++)c+="0";for(f=Zc(c,i,e),l=f.length;!f[l-1];--l);for(s=1,c="1.";s<l;s++)c+=Wd.charAt(f[s])}else c=c.charAt(0)+"."+c.slice(1);c=c+(o<0?"p":"p+")+o}else if(o<0){for(;++o;)c="0"+c;c="0."+c}else if(++o>l)for(o-=l;o--;)c+="0";else o<l&&(c=c.slice(0,o)+"."+c.slice(o))}c=(e==16?"0x":e==2?"0b":e==8?"0o":"")+c}return t.s<0?"-"+c:c}function Tv(t,e){if(t.length>e)return t.length=e,!0}function $A(t){return new this(t).abs()}function JA(t){return new this(t).acos()}function KA(t){return new this(t).acosh()}function QA(t,e){return new this(t).plus(e)}function jA(t){return new this(t).asin()}function eC(t){return new this(t).asinh()}function tC(t){return new this(t).atan()}function nC(t){return new this(t).atanh()}function rC(t,e){t=new this(t),e=new this(e);var n,r=this.precision,i=this.rounding,o=r+4;return!t.s||!e.s?n=new this(NaN):!t.d&&!e.d?(n=xr(this,o,1).times(e.s>0?.25:.75),n.s=t.s):!e.d||t.isZero()?(n=e.s<0?xr(this,r,i):new this(0),n.s=t.s):!t.d||e.isZero()?(n=xr(this,o,1).times(.5),n.s=t.s):e.s<0?(this.precision=o,this.rounding=1,n=this.atan(Mt(t,e,o,1)),e=xr(this,o,1),this.precision=r,this.rounding=i,n=t.s<0?n.minus(e):n.plus(e)):n=this.atan(Mt(t,e,o,1)),n}function iC(t){return new this(t).cbrt()}function oC(t){return Ue(t=new this(t),t.e+1,2)}function sC(t,e,n){return new this(t).clamp(e,n)}function aC(t){if(!t||typeof t!="object")throw Error(jc+"Object expected");var e,n,r,i=t.defaults===!0,o=["precision",1,di,"rounding",0,8,"toExpNeg",-jo,0,"toExpPos",0,jo,"maxE",0,jo,"minE",-jo,0,"modulo",0,9];for(e=0;e<o.length;e+=3)if(n=o[e],i&&(this[n]=qd[n]),(r=t[n])!==void 0)if(rn(r)===r&&r>=o[e+1]&&r<=o[e+2])this[n]=r;else throw Error(hi+n+": "+r);if(n="crypto",i&&(this[n]=qd[n]),(r=t[n])!==void 0)if(r===!0||r===!1||r===0||r===1)if(r)if(typeof crypto<"u"&&crypto&&(crypto.getRandomValues||crypto.randomBytes))this[n]=!0;else throw Error(Iv);else this[n]=!1;else throw Error(hi+n+": "+r);return this}function uC(t){return new this(t).cos()}function lC(t){return new this(t).cosh()}function Vv(t){var e,n,r;function i(o){var s,a,l,u=this;if(!(u instanceof i))return new i(o);if(u.constructor=i,Rv(o)){u.s=o.s,Ye?!o.d||o.e>i.maxE?(u.e=NaN,u.d=null):o.e<i.minE?(u.e=0,u.d=[0]):(u.e=o.e,u.d=o.d.slice()):(u.e=o.e,u.d=o.d?o.d.slice():o.d);return}if(l=typeof o,l==="number"){if(o===0){u.s=1/o<0?-1:1,u.e=0,u.d=[0];return}if(o<0?(o=-o,u.s=-1):u.s=1,o===~~o&&o<1e7){for(s=0,a=o;a>=10;a/=10)s++;Ye?s>i.maxE?(u.e=NaN,u.d=null):s<i.minE?(u.e=0,u.d=[0]):(u.e=s,u.d=[o]):(u.e=s,u.d=[o]);return}if(o*0!==0){o||(u.s=NaN),u.e=NaN,u.d=null;return}return $c(u,o.toString())}if(l==="string")return(a=o.charCodeAt(0))===45?(o=o.slice(1),u.s=-1):(a===43&&(o=o.slice(1)),u.s=1),Lv.test(o)?$c(u,o):YA(u,o);if(l==="bigint")return o<0?(o=-o,u.s=-1):u.s=1,$c(u,o.toString());throw Error(hi+o)}if(i.prototype=he,i.ROUND_UP=0,i.ROUND_DOWN=1,i.ROUND_CEIL=2,i.ROUND_FLOOR=3,i.ROUND_HALF_UP=4,i.ROUND_HALF_DOWN=5,i.ROUND_HALF_EVEN=6,i.ROUND_HALF_CEIL=7,i.ROUND_HALF_FLOOR=8,i.EUCLID=9,i.config=i.set=aC,i.clone=Vv,i.isDecimal=Rv,i.abs=$A,i.acos=JA,i.acosh=KA,i.add=QA,i.asin=jA,i.asinh=eC,i.atan=tC,i.atanh=nC,i.atan2=rC,i.cbrt=iC,i.ceil=oC,i.clamp=sC,i.cos=uC,i.cosh=lC,i.div=cC,i.exp=fC,i.floor=hC,i.hypot=dC,i.ln=pC,i.log=mC,i.log10=xC,i.log2=gC,i.max=vC,i.min=_C,i.mod=yC,i.mul=MC,i.pow=SC,i.random=wC,i.round=bC,i.sign=EC,i.sin=DC,i.sinh=AC,i.sqrt=CC,i.sub=TC,i.sum=RC,i.tan=FC,i.tanh=PC,i.trunc=IC,t===void 0&&(t={}),t&&t.defaults!==!0)for(r=["precision","rounding","toExpNeg","toExpPos","maxE","minE","modulo","crypto"],e=0;e<r.length;)t.hasOwnProperty(n=r[e++])||(t[n]=this[n]);return i.config(t),i}function cC(t,e){return new this(t).div(e)}function fC(t){return new this(t).exp()}function hC(t){return Ue(t=new this(t),t.e+1,3)}function dC(){var t,e,n=new this(0);for(Ye=!1,t=0;t<arguments.length;)if(e=new this(arguments[t++]),e.d)n.d&&(n=n.plus(e.times(e)));else{if(e.s)return Ye=!0,new this(1/0);n=e}return Ye=!0,n.sqrt()}function Rv(t){return t instanceof _a||t&&t.toStringTag===Nv||!1}function pC(t){return new this(t).ln()}function mC(t,e){return new this(t).log(e)}function gC(t){return new this(t).log(2)}function xC(t){return new this(t).log(10)}function vC(){return Ov(this,arguments,-1)}function _C(){return Ov(this,arguments,1)}function yC(t,e){return new this(t).mod(e)}function MC(t,e){return new this(t).mul(e)}function SC(t,e){return new this(t).pow(e)}function wC(t){var e,n,r,i,o=0,s=new this(1),a=[];if(t===void 0?t=this.precision:vn(t,1,di),r=Math.ceil(t/Ge),this.crypto)if(crypto.getRandomValues)for(e=crypto.getRandomValues(new Uint32Array(r));o<r;)i=e[o],i>=429e7?e[o]=crypto.getRandomValues(new Uint32Array(1))[0]:a[o++]=i%1e7;else if(crypto.randomBytes){for(e=crypto.randomBytes(r*=4);o<r;)i=e[o]+(e[o+1]<<8)+(e[o+2]<<16)+((e[o+3]&127)<<24),i>=214e7?crypto.randomBytes(4).copy(e,o):(a.push(i%1e7),o+=4);o=r/4}else throw Error(Iv);else for(;o<r;)a[o++]=Math.random()*1e7|0;for(r=a[--o],t%=Ge,r&&t&&(i=Vt(10,Ge-t),a[o]=(r/i|0)*i);a[o]===0;o--)a.pop();if(o<0)n=0,a=[0];else{for(n=-1;a[0]===0;n-=Ge)a.shift();for(r=1,i=a[0];i>=10;i/=10)r++;r<Ge&&(n-=Ge-r)}return s.e=n,s.d=a,s}function bC(t){return Ue(t=new this(t),t.e+1,this.rounding)}function EC(t){return t=new this(t),t.d?t.d[0]?t.s:0*t.s:t.s||NaN}function DC(t){return new this(t).sin()}function AC(t){return new this(t).sinh()}function CC(t){return new this(t).sqrt()}function TC(t,e){return new this(t).sub(e)}function RC(){var t=0,e=arguments,n=new this(e[t]);for(Ye=!1;n.s&&++t<e.length;)n=n.plus(e[t]);return Ye=!0,Ue(n,this.precision,this.rounding)}function FC(t){return new this(t).tan()}function PC(t){return new this(t).tanh()}function IC(t){return Ue(t=new this(t),t.e+1,1)}he[Symbol.for("nodejs.util.inspect.custom")]=he.toString;he[Symbol.toStringTag]="Decimal";var _a=he.constructor=Vv(qd);Jc=new _a(Jc);Kc=new _a(Kc);var $d=_a;var NC="BigNumber",LC=["?on","config"],Jd=ve(NC,LC,t=>{var{on:e,config:n}=t,r=$d.clone({precision:n.precision,modulo:$d.EUCLID});return r.prototype=Object.create(r.prototype),r.prototype.type="BigNumber",r.prototype.isBigNumber=!0,r.prototype.toJSON=function(){return{mathjs:"BigNumber",value:this.toString()}},r.fromJSON=function(i){return new r(i.value)},e&&e("config",function(i,o){i.precision!==o.precision&&r.config({precision:i.precision})}),r},{isClass:!0});var on=Math.cosh||function(t){return Math.abs(t)<1e-9?1-t:(Math.exp(t)+Math.exp(-t))*.5},qn=Math.sinh||function(t){return Math.abs(t)<1e-9?t:(Math.exp(t)-Math.exp(-t))*.5},BC=t=>{let e=Math.sin(.5*t);return-2*e*e},Kd=function(t,e){return t=Math.abs(t),e=Math.abs(e),t<e&&([t,e]=[e,t]),t<1e8?Math.sqrt(t*t+e*e):(e/=t,t*Math.sqrt(1+e*e))},ts=function(){throw SyntaxError("Invalid Param")};function Qd(t,e){let n=Math.abs(t),r=Math.abs(e);return t===0?Math.log(r):e===0?Math.log(n):n<3e3&&r<3e3?Math.log(t*t+e*e)*.5:(t=t*.5,e=e*.5,.5*Math.log(t*t+e*e)+Math.LN2)}var UC={re:0,im:0},to=function(t,e){let n=UC;if(t==null)n.re=n.im=0;else if(e!==void 0)n.re=t,n.im=e;else switch(typeof t){case"object":if("im"in t&&"re"in t)n.re=t.re,n.im=t.im;else if("abs"in t&&"arg"in t){if(!isFinite(t.abs)&&isFinite(t.arg))return K.INFINITY;n.re=t.abs*Math.cos(t.arg),n.im=t.abs*Math.sin(t.arg)}else if("r"in t&&"phi"in t){if(!isFinite(t.r)&&isFinite(t.phi))return K.INFINITY;n.re=t.r*Math.cos(t.phi),n.im=t.r*Math.sin(t.phi)}else t.length===2?(n.re=t[0],n.im=t[1]):ts();break;case"string":n.im=n.re=0;let r=t.replace(/_/g,"").match(/\d+\.?\d*e[+-]?\d+|\d+\.?\d*|\.\d+|./g),i=1,o=0;r===null&&ts();for(let s=0;s<r.length;s++){let a=r[s];a===" "||a==="	"||a===`
`||(a==="+"?i++:a==="-"?o++:a==="i"||a==="I"?(i+o===0&&ts(),r[s+1]!==" "&&!isNaN(r[s+1])?(n.im+=parseFloat((o%2?"-":"")+r[s+1]),s++):n.im+=parseFloat((o%2?"-":"")+"1"),i=o=0):((i+o===0||isNaN(a))&&ts(),r[s+1]==="i"||r[s+1]==="I"?(n.im+=parseFloat((o%2?"-":"")+a),s++):n.re+=parseFloat((o%2?"-":"")+a),i=o=0))}i+o>0&&ts();break;case"number":n.im=0,n.re=t;break;default:ts()}return isNaN(n.re)||isNaN(n.im),n};function K(t,e){if(!(this instanceof K))return new K(t,e);let n=to(t,e);this.re=n.re,this.im=n.im}K.prototype={re:0,im:0,sign:function(){let t=Kd(this.re,this.im);return new K(this.re/t,this.im/t)},add:function(t,e){let n=to(t,e),r=this.isInfinite(),i=!(isFinite(n.re)&&isFinite(n.im));return r||i?r&&i?K.NAN:K.INFINITY:new K(this.re+n.re,this.im+n.im)},sub:function(t,e){let n=to(t,e),r=this.isInfinite(),i=!(isFinite(n.re)&&isFinite(n.im));return r||i?r&&i?K.NAN:K.INFINITY:new K(this.re-n.re,this.im-n.im)},mul:function(t,e){let n=to(t,e),r=this.isInfinite(),i=!(isFinite(n.re)&&isFinite(n.im)),o=this.re===0&&this.im===0,s=n.re===0&&n.im===0;return r&&s||i&&o?K.NAN:r||i?K.INFINITY:n.im===0&&this.im===0?new K(this.re*n.re,0):new K(this.re*n.re-this.im*n.im,this.re*n.im+this.im*n.re)},div:function(t,e){let n=to(t,e),r=this.isInfinite(),i=!(isFinite(n.re)&&isFinite(n.im)),o=this.re===0&&this.im===0,s=n.re===0&&n.im===0;if(o&&s||r&&i)return K.NAN;if(s||r)return K.INFINITY;if(o||i)return K.ZERO;if(n.im===0)return new K(this.re/n.re,this.im/n.re);if(Math.abs(n.re)<Math.abs(n.im)){let a=n.re/n.im,l=n.re*a+n.im;return new K((this.re*a+this.im)/l,(this.im*a-this.re)/l)}else{let a=n.im/n.re,l=n.im*a+n.re;return new K((this.re+this.im*a)/l,(this.im-this.re*a)/l)}},pow:function(t,e){let n=to(t,e),r=this.re===0&&this.im===0;if(n.re===0&&n.im===0)return K.ONE;if(n.im===0){if(this.im===0&&this.re>0)return new K(Math.pow(this.re,n.re),0);if(this.re===0)switch((n.re%4+4)%4){case 0:return new K(Math.pow(this.im,n.re),0);case 1:return new K(0,Math.pow(this.im,n.re));case 2:return new K(-Math.pow(this.im,n.re),0);case 3:return new K(0,-Math.pow(this.im,n.re))}}if(r&&n.re>0)return K.ZERO;let o=Math.atan2(this.im,this.re),s=Qd(this.re,this.im),a=Math.exp(n.re*s-n.im*o),l=n.im*s+n.re*o;return new K(a*Math.cos(l),a*Math.sin(l))},sqrt:function(){let t=this.re,e=this.im;if(e===0)return t>=0?new K(Math.sqrt(t),0):new K(0,Math.sqrt(-t));let n=Kd(t,e),r=Math.sqrt(.5*(n+Math.abs(t))),i=Math.abs(e)/(2*r);return t>=0?new K(r,e<0?-i:i):new K(i,e<0?-r:r)},exp:function(){let t=Math.exp(this.re);return this.im===0?new K(t,0):new K(t*Math.cos(this.im),t*Math.sin(this.im))},expm1:function(){let t=this.re,e=this.im;return new K(Math.expm1(t)*Math.cos(e)+BC(e),Math.exp(t)*Math.sin(e))},log:function(){let t=this.re,e=this.im;return e===0&&t>0?new K(Math.log(t),0):new K(Qd(t,e),Math.atan2(e,t))},abs:function(){return Kd(this.re,this.im)},arg:function(){return Math.atan2(this.im,this.re)},sin:function(){let t=this.re,e=this.im;return new K(Math.sin(t)*on(e),Math.cos(t)*qn(e))},cos:function(){let t=this.re,e=this.im;return new K(Math.cos(t)*on(e),-Math.sin(t)*qn(e))},tan:function(){let t=2*this.re,e=2*this.im,n=Math.cos(t)+on(e);return new K(Math.sin(t)/n,qn(e)/n)},cot:function(){let t=2*this.re,e=2*this.im,n=Math.cos(t)-on(e);return new K(-Math.sin(t)/n,qn(e)/n)},sec:function(){let t=this.re,e=this.im,n=.5*on(2*e)+.5*Math.cos(2*t);return new K(Math.cos(t)*on(e)/n,Math.sin(t)*qn(e)/n)},csc:function(){let t=this.re,e=this.im,n=.5*on(2*e)-.5*Math.cos(2*t);return new K(Math.sin(t)*on(e)/n,-Math.cos(t)*qn(e)/n)},asin:function(){let t=this.re,e=this.im,n=new K(e*e-t*t+1,-2*t*e).sqrt(),r=new K(n.re-e,n.im+t).log();return new K(r.im,-r.re)},acos:function(){let t=this.re,e=this.im,n=new K(e*e-t*t+1,-2*t*e).sqrt(),r=new K(n.re-e,n.im+t).log();return new K(Math.PI/2-r.im,r.re)},atan:function(){let t=this.re,e=this.im;if(t===0){if(e===1)return new K(0,1/0);if(e===-1)return new K(0,-1/0)}let n=t*t+(1-e)*(1-e),r=new K((1-e*e-t*t)/n,-2*t/n).log();return new K(-.5*r.im,.5*r.re)},acot:function(){let t=this.re,e=this.im;if(e===0)return new K(Math.atan2(1,t),0);let n=t*t+e*e;return n!==0?new K(t/n,-e/n).atan():new K(t!==0?t/0:0,e!==0?-e/0:0).atan()},asec:function(){let t=this.re,e=this.im;if(t===0&&e===0)return new K(0,1/0);let n=t*t+e*e;return n!==0?new K(t/n,-e/n).acos():new K(t!==0?t/0:0,e!==0?-e/0:0).acos()},acsc:function(){let t=this.re,e=this.im;if(t===0&&e===0)return new K(Math.PI/2,1/0);let n=t*t+e*e;return n!==0?new K(t/n,-e/n).asin():new K(t!==0?t/0:0,e!==0?-e/0:0).asin()},sinh:function(){let t=this.re,e=this.im;return new K(qn(t)*Math.cos(e),on(t)*Math.sin(e))},cosh:function(){let t=this.re,e=this.im;return new K(on(t)*Math.cos(e),qn(t)*Math.sin(e))},tanh:function(){let t=2*this.re,e=2*this.im,n=on(t)+Math.cos(e);return new K(qn(t)/n,Math.sin(e)/n)},coth:function(){let t=2*this.re,e=2*this.im,n=on(t)-Math.cos(e);return new K(qn(t)/n,-Math.sin(e)/n)},csch:function(){let t=this.re,e=this.im,n=Math.cos(2*e)-on(2*t);return new K(-2*qn(t)*Math.cos(e)/n,2*on(t)*Math.sin(e)/n)},sech:function(){let t=this.re,e=this.im,n=Math.cos(2*e)+on(2*t);return new K(2*on(t)*Math.cos(e)/n,-2*qn(t)*Math.sin(e)/n)},asinh:function(){let t=this.re,e=this.im;if(e===0){if(t===0)return new K(0,0);let o=Math.abs(t),s=Math.log(o+Math.sqrt(o*o+1));return new K(t<0?-s:s,0)}let n=t*t-e*e+1,r=2*t*e,i=new K(n,r).sqrt();return new K(t+i.re,e+i.im).log()},acosh:function(){let t=this.re,e=this.im;if(e===0){if(t>1)return new K(Math.log(t+Math.sqrt(t-1)*Math.sqrt(t+1)),0);if(t<-1){let i=Math.sqrt(t*t-1);return new K(Math.log(-t+i),Math.PI)}return new K(0,Math.acos(t))}let n=new K(t-1,e).sqrt(),r=new K(t+1,e).sqrt();return new K(t+n.re*r.re-n.im*r.im,e+n.re*r.im+n.im*r.re).log()},atanh:function(){let t=this.re,e=this.im;if(e===0){if(t===0)return new K(0,0);if(t===1)return new K(1/0,0);if(t===-1)return new K(-1/0,0);if(-1<t&&t<1)return new K(.5*Math.log((1+t)/(1-t)),0);if(t>1){let l=(t+1)/(t-1);return new K(.5*Math.log(l),-Math.PI/2)}let a=(1+t)/(1-t);return new K(.5*Math.log(-a),Math.PI/2)}let n=1-t,r=1+t,i=n*n+e*e;if(i===0)return new K(t!==-1?t/0:0,e!==0?e/0:0);let o=(r*n-e*e)/i,s=(e*n+r*e)/i;return new K(Qd(o,s)/2,Math.atan2(s,o)/2)},acoth:function(){let t=this.re,e=this.im;if(t===0&&e===0)return new K(0,Math.PI/2);let n=t*t+e*e;return n!==0?new K(t/n,-e/n).atanh():new K(t!==0?t/0:0,e!==0?-e/0:0).atanh()},acsch:function(){let t=this.re,e=this.im;if(e===0){if(t===0)return new K(1/0,0);let r=1/t;return new K(Math.log(r+Math.sqrt(r*r+1)),0)}let n=t*t+e*e;return n!==0?new K(t/n,-e/n).asinh():new K(t!==0?t/0:0,e!==0?-e/0:0).asinh()},asech:function(){let t=this.re,e=this.im;if(this.isZero())return K.INFINITY;let n=t*t+e*e;return n!==0?new K(t/n,-e/n).acosh():new K(t!==0?t/0:0,e!==0?-e/0:0).acosh()},inverse:function(){if(this.isZero())return K.INFINITY;if(this.isInfinite())return K.ZERO;let t=this.re,e=this.im,n=t*t+e*e;return new K(t/n,-e/n)},conjugate:function(){return new K(this.re,-this.im)},neg:function(){return new K(-this.re,-this.im)},ceil:function(t){return t=Math.pow(10,t||0),new K(Math.ceil(this.re*t)/t,Math.ceil(this.im*t)/t)},floor:function(t){return t=Math.pow(10,t||0),new K(Math.floor(this.re*t)/t,Math.floor(this.im*t)/t)},round:function(t){return t=Math.pow(10,t||0),new K(Math.round(this.re*t)/t,Math.round(this.im*t)/t)},equals:function(t,e){let n=to(t,e);return Math.abs(n.re-this.re)<=K.EPSILON&&Math.abs(n.im-this.im)<=K.EPSILON},clone:function(){return new K(this.re,this.im)},toString:function(){let t=this.re,e=this.im,n="";return this.isNaN()?"NaN":this.isInfinite()?"Infinity":(Math.abs(t)<K.EPSILON&&(t=0),Math.abs(e)<K.EPSILON&&(e=0),e===0?n+t:(t!==0?(n+=t,n+=" ",e<0?(e=-e,n+="-"):n+="+",n+=" "):e<0&&(e=-e,n+="-"),e!==1&&(n+=e),n+"i"))},toVector:function(){return[this.re,this.im]},valueOf:function(){return this.im===0?this.re:null},isNaN:function(){return isNaN(this.re)||isNaN(this.im)},isZero:function(){return this.im===0&&this.re===0},isFinite:function(){return isFinite(this.re)&&isFinite(this.im)},isInfinite:function(){return!this.isFinite()}};K.ZERO=new K(0,0);K.ONE=new K(1,0);K.I=new K(0,1);K.PI=new K(Math.PI,0);K.E=new K(Math.E,0);K.INFINITY=new K(1/0,1/0);K.NAN=new K(NaN,NaN);K.EPSILON=1e-15;var OC="Complex",zC=[],jd=ve(OC,zC,()=>(Object.defineProperty(K,"name",{value:"Complex"}),K.prototype.constructor=K,K.prototype.type="Complex",K.prototype.isComplex=!0,K.prototype.toJSON=function(){return{mathjs:"Complex",re:this.re,im:this.im}},K.prototype.toPolar=function(){return{r:this.abs(),phi:this.arg()}},K.prototype.format=function(t){var e="",n=this.im,r=this.re,i=xa(this.re,t),o=xa(this.im,t),s=ot(t)?t:t?t.precision:null;if(s!==null){var a=Math.pow(10,-s);Math.abs(r/n)<a&&(r=0),Math.abs(n/r)<a&&(n=0)}return n===0?e=i:r===0?n===1?e="i":n===-1?e="-i":e=o+"i":n<0?n===-1?e=i+" - i":e=i+" - "+o.substring(1)+"i":n===1?e=i+" + i":e=i+" + "+o+"i",e},K.fromPolar=function(t){switch(arguments.length){case 1:{var e=arguments[0];if(typeof e=="object")return K(e);throw new TypeError("Input has to be an object with r and phi keys.")}case 2:{var n=arguments[0],r=arguments[1];if(ot(n)){if(ui(r)&&r.hasBase("ANGLE")&&(r=r.toNumber("rad")),ot(r))return new K({r:n,phi:r});throw new TypeError("Phi is not a number nor an angle unit.")}else throw new TypeError("Radius r is not a number.")}default:throw new SyntaxError("Wrong number of arguments in function fromPolar")}},K.prototype.valueOf=K.prototype.toString,K.fromJSON=function(t){return new K(t)},K.compare=function(t,e){return t.re>e.re?1:t.re<e.re?-1:t.im>e.im?1:t.im<e.im?-1:0},K),{isClass:!0});typeof BigInt>"u"&&(BigInt=function(t){if(isNaN(t))throw new Error("");return t});var Le=BigInt(0),et=BigInt(1),Zt=BigInt(2),ya=BigInt(3),rs=BigInt(5),_n=BigInt(10),W4=BigInt(Number.MAX_SAFE_INTEGER),kC=2e3,Me={s:et,n:Le,d:et};function Br(t,e){try{t=BigInt(t)}catch{throw pi()}return t*e}function or(t){return typeof t=="bigint"?t:Math.floor(t)}function Dt(t,e){if(e===Le)throw ep();let n=Object.create(Pn.prototype);n.s=t<Le?-et:et,t=t<Le?-t:t;let r=no(t,e);return n.n=t/r,n.d=e/r,n}var VC=[Zt*Zt,Zt,Zt*Zt,Zt,Zt*Zt,Zt*ya,Zt,Zt*ya];function ns(t){let e=Object.create(null);if(t<=et)return e[t]=et,e;let n=r=>{e[r]=(e[r]||Le)+et};for(;t%Zt===Le;)n(Zt),t/=Zt;for(;t%ya===Le;)n(ya),t/=ya;for(;t%rs===Le;)n(rs),t/=rs;for(let r=0,i=Zt+rs;i*i<=t;){for(;t%i===Le;)n(i),t/=i;i+=VC[r],r=r+1&7}return t>et&&n(t),e}var Yt=function(t,e){let n=Le,r=et,i=et;if(t!=null)if(e!==void 0){if(typeof t=="bigint")n=t;else{if(isNaN(t))throw pi();if(t%1!==0)throw Hv();n=BigInt(t)}if(typeof e=="bigint")r=e;else{if(isNaN(e))throw pi();if(e%1!==0)throw Hv();r=BigInt(e)}i=n*r}else if(typeof t=="object"){if("d"in t&&"n"in t)n=BigInt(t.n),r=BigInt(t.d),"s"in t&&(n*=BigInt(t.s));else if(0 in t)n=BigInt(t[0]),1 in t&&(r=BigInt(t[1]));else if(typeof t=="bigint")n=t;else throw pi();i=n*r}else if(typeof t=="number"){if(isNaN(t))throw pi();if(t<0&&(i=-et,t=-t),t%1===0)n=BigInt(t);else{let o=1,s=0,a=1,l=1,u=1,c=1e7;for(t>=1&&(o=10**Math.floor(1+Math.log10(t)),t/=o);a<=c&&u<=c;){let f=(s+l)/(a+u);if(t===f){a+u<=c?(n=s+l,r=a+u):u>a?(n=l,r=u):(n=s,r=a);break}else t>f?(s+=l,a+=u):(l+=s,u+=a),a>c?(n=l,r=u):(n=s,r=a)}n=BigInt(n)*BigInt(o),r=BigInt(r)}}else if(typeof t=="string"){let o=0,s=Le,a=Le,l=Le,u=et,c=et,f=t.replace(/_/g,"").match(/\d+|./g);if(f===null)throw pi();if(f[o]==="-"?(i=-et,o++):f[o]==="+"&&o++,f.length===o+1?a=Br(f[o++],i):f[o+1]==="."||f[o]==="."?(f[o]!=="."&&(s=Br(f[o++],i)),o++,(o+1===f.length||f[o+1]==="("&&f[o+3]===")"||f[o+1]==="'"&&f[o+3]==="'")&&(a=Br(f[o],i),u=_n**BigInt(f[o].length),o++),(f[o]==="("&&f[o+2]===")"||f[o]==="'"&&f[o+2]==="'")&&(l=Br(f[o+1],i),c=_n**BigInt(f[o+1].length)-et,o+=3)):f[o+1]==="/"||f[o+1]===":"?(a=Br(f[o],i),u=Br(f[o+2],et),o+=3):f[o+3]==="/"&&f[o+1]===" "&&(s=Br(f[o],i),a=Br(f[o+2],i),u=Br(f[o+4],et),o+=5),f.length<=o)r=u*c,i=n=l+r*s+c*a;else throw pi()}else if(typeof t=="bigint")n=t,i=t,r=et;else throw pi();if(r===Le)throw ep();Me.s=i<Le?-et:et,Me.n=n<Le?-n:n,Me.d=r<Le?-r:r};function HC(t,e,n){let r=et;for(;e>Le;t=t*t%n,e>>=et)e&et&&(r=r*t%n);return r}function GC(t,e){for(;e%Zt===Le;e/=Zt);for(;e%rs===Le;e/=rs);if(e===et)return Le;let n=_n%e,r=1;for(;n!==et;r++)if(n=n*_n%e,r>kC)return Le;return BigInt(r)}function WC(t,e,n){let r=et,i=HC(_n,n,e);for(let o=0;o<300;o++){if(r===i)return BigInt(o);r=r*_n%e,i=i*_n%e}return 0}function no(t,e){if(!t)return e;if(!e)return t;for(;;){if(t%=e,!t)return e;if(e%=t,!e)return t}}function Pn(t,e){if(Yt(t,e),this instanceof Pn)t=no(Me.d,Me.n),this.s=Me.s,this.n=Me.n/t,this.d=Me.d/t;else return Dt(Me.s*Me.n,Me.d)}var ep=function(){return new Error("Division by Zero")},pi=function(){return new Error("Invalid argument")},Hv=function(){return new Error("Parameters must be integer")};Pn.prototype={s:et,n:Le,d:et,abs:function(){return Dt(this.n,this.d)},neg:function(){return Dt(-this.s*this.n,this.d)},add:function(t,e){return Yt(t,e),Dt(this.s*this.n*Me.d+Me.s*this.d*Me.n,this.d*Me.d)},sub:function(t,e){return Yt(t,e),Dt(this.s*this.n*Me.d-Me.s*this.d*Me.n,this.d*Me.d)},mul:function(t,e){return Yt(t,e),Dt(this.s*Me.s*this.n*Me.n,this.d*Me.d)},div:function(t,e){return Yt(t,e),Dt(this.s*Me.s*this.n*Me.d,this.d*Me.n)},clone:function(){return Dt(this.s*this.n,this.d)},mod:function(t,e){if(t===void 0)return Dt(this.s*this.n%this.d,et);if(Yt(t,e),Le===Me.n*this.d)throw ep();return Dt(this.s*(Me.d*this.n)%(Me.n*this.d),Me.d*this.d)},gcd:function(t,e){return Yt(t,e),Dt(no(Me.n,this.n)*no(Me.d,this.d),Me.d*this.d)},lcm:function(t,e){return Yt(t,e),Me.n===Le&&this.n===Le?Dt(Le,et):Dt(Me.n*this.n,no(Me.n,this.n)*no(Me.d,this.d))},inverse:function(){return Dt(this.s*this.d,this.n)},pow:function(t,e){if(Yt(t,e),Me.d===et)return Me.s<Le?Dt((this.s*this.d)**Me.n,this.n**Me.n):Dt((this.s*this.n)**Me.n,this.d**Me.n);if(this.s<Le)return null;let n=ns(this.n),r=ns(this.d),i=et,o=et;for(let s in n)if(s!=="1"){if(s==="0"){i=Le;break}if(n[s]*=Me.n,n[s]%Me.d===Le)n[s]/=Me.d;else return null;i*=BigInt(s)**n[s]}for(let s in r)if(s!=="1"){if(r[s]*=Me.n,r[s]%Me.d===Le)r[s]/=Me.d;else return null;o*=BigInt(s)**r[s]}return Me.s<Le?Dt(o,i):Dt(i,o)},log:function(t,e){if(Yt(t,e),this.s<=Le||Me.s<=Le)return null;let n=Object.create(null),r=ns(Me.n),i=ns(Me.d),o=ns(this.n),s=ns(this.d);for(let u in i)r[u]=(r[u]||Le)-i[u];for(let u in s)o[u]=(o[u]||Le)-s[u];for(let u in r)u!=="1"&&(n[u]=!0);for(let u in o)u!=="1"&&(n[u]=!0);let a=null,l=null;for(let u in n){let c=r[u]||Le,f=o[u]||Le;if(c===Le){if(f!==Le)return null;continue}let h=f,d=c,x=no(h,d);if(h/=x,d/=x,a===null&&l===null)a=h,l=d;else if(h*l!==a*d)return null}return a!==null&&l!==null?Dt(a,l):null},equals:function(t,e){return Yt(t,e),this.s*this.n*Me.d===Me.s*Me.n*this.d},lt:function(t,e){return Yt(t,e),this.s*this.n*Me.d<Me.s*Me.n*this.d},lte:function(t,e){return Yt(t,e),this.s*this.n*Me.d<=Me.s*Me.n*this.d},gt:function(t,e){return Yt(t,e),this.s*this.n*Me.d>Me.s*Me.n*this.d},gte:function(t,e){return Yt(t,e),this.s*this.n*Me.d>=Me.s*Me.n*this.d},compare:function(t,e){Yt(t,e);let n=this.s*this.n*Me.d-Me.s*Me.n*this.d;return(Le<n)-(n<Le)},ceil:function(t){return t=_n**BigInt(t||0),Dt(or(this.s*t*this.n/this.d)+(t*this.n%this.d>Le&&this.s>=Le?et:Le),t)},floor:function(t){return t=_n**BigInt(t||0),Dt(or(this.s*t*this.n/this.d)-(t*this.n%this.d>Le&&this.s<Le?et:Le),t)},round:function(t){return t=_n**BigInt(t||0),Dt(or(this.s*t*this.n/this.d)+this.s*((this.s>=Le?et:Le)+Zt*(t*this.n%this.d)>this.d?et:Le),t)},roundTo:function(t,e){Yt(t,e);let n=this.n*Me.d,r=this.d*Me.n,i=n%r,o=or(n/r);return i+i>=r&&o++,Dt(this.s*o*Me.n,Me.d)},divisible:function(t,e){return Yt(t,e),Me.n===Le?!1:this.n*Me.d%(Me.n*this.d)===Le},valueOf:function(){return Number(this.s*this.n)/Number(this.d)},toString:function(t=15){let e=this.n,n=this.d,r=GC(e,n),i=WC(e,n,r),o=this.s<Le?"-":"";if(o+=or(e/n),e%=n,e*=_n,e&&(o+="."),r){for(let s=i;s--;)o+=or(e/n),e%=n,e*=_n;o+="(";for(let s=r;s--;)o+=or(e/n),e%=n,e*=_n;o+=")"}else for(let s=t;e&&s--;)o+=or(e/n),e%=n,e*=_n;return o},toFraction:function(t=!1){let e=this.n,n=this.d,r=this.s<Le?"-":"";if(n===et)r+=e;else{let i=or(e/n);t&&i>Le&&(r+=i,r+=" ",e%=n),r+=e,r+="/",r+=n}return r},toLatex:function(t=!1){let e=this.n,n=this.d,r=this.s<Le?"-":"";if(n===et)r+=e;else{let i=or(e/n);t&&i>Le&&(r+=i,e%=n),r+="\\frac{",r+=e,r+="}{",r+=n,r+="}"}return r},toContinued:function(){let t=this.n,e=this.d,n=[];for(;e;){n.push(or(t/e));let r=t%e;t=e,e=r}return n},simplify:function(t=.001){let e=BigInt(Math.ceil(1/t)),n=this.abs(),r=n.toContinued();for(let i=1;i<r.length;i++){let o=Dt(r[i-1],et);for(let a=i-2;a>=0;a--)o=o.inverse().add(r[a]);let s=o.sub(n);if(s.n*e<s.d)return o.mul(this.s)}return this}};var qC="Fraction",XC=[],tp=ve(qC,XC,()=>(Object.defineProperty(Pn,"name",{value:"Fraction"}),Pn.prototype.constructor=Pn,Pn.prototype.type="Fraction",Pn.prototype.isFraction=!0,Pn.prototype.toJSON=function(){return{mathjs:"Fraction",n:String(this.s*this.n),d:String(this.d)}},Pn.fromJSON=function(t){return new Pn(t)},Pn),{isClass:!0});var YC="Matrix",ZC=[],np=ve(YC,ZC,()=>{function t(){if(!(this instanceof t))throw new SyntaxError("Constructor must be called with the new operator")}return t.prototype.type="Matrix",t.prototype.isMatrix=!0,t.prototype.storage=function(){throw new Error("Cannot invoke storage on a Matrix interface")},t.prototype.datatype=function(){throw new Error("Cannot invoke datatype on a Matrix interface")},t.prototype.create=function(e,n){throw new Error("Cannot invoke create on a Matrix interface")},t.prototype.subset=function(e,n,r){throw new Error("Cannot invoke subset on a Matrix interface")},t.prototype.get=function(e){throw new Error("Cannot invoke get on a Matrix interface")},t.prototype.set=function(e,n,r){throw new Error("Cannot invoke set on a Matrix interface")},t.prototype.resize=function(e,n){throw new Error("Cannot invoke resize on a Matrix interface")},t.prototype.reshape=function(e,n){throw new Error("Cannot invoke reshape on a Matrix interface")},t.prototype.clone=function(){throw new Error("Cannot invoke clone on a Matrix interface")},t.prototype.size=function(){throw new Error("Cannot invoke size on a Matrix interface")},t.prototype.map=function(e,n){throw new Error("Cannot invoke map on a Matrix interface")},t.prototype.forEach=function(e){throw new Error("Cannot invoke forEach on a Matrix interface")},t.prototype[Symbol.iterator]=function(){throw new Error("Cannot iterate a Matrix interface")},t.prototype.toArray=function(){throw new Error("Cannot invoke toArray on a Matrix interface")},t.prototype.valueOf=function(){throw new Error("Cannot invoke valueOf on a Matrix interface")},t.prototype.format=function(e){throw new Error("Cannot invoke format on a Matrix interface")},t.prototype.toString=function(){throw new Error("Cannot invoke toString on a Matrix interface")},t},{isClass:!0});function rp(t,e,n){var r=t.constructor,i=new r(2),o="";if(n){if(n<1)throw new Error("size must be in greater than 0");if(!ht(n))throw new Error("size must be an integer");if(t.greaterThan(i.pow(n-1).sub(1))||t.lessThan(i.pow(n-1).mul(-1)))throw new Error("Value must be in range [-2^".concat(n-1,", 2^").concat(n-1,"-1]"));if(!t.isInteger())throw new Error("Value must be an integer");t.lessThan(0)&&(t=t.add(i.pow(n))),o="i".concat(n)}switch(e){case 2:return"".concat(t.toBinary()).concat(o);case 8:return"".concat(t.toOctal()).concat(o);case 16:return"".concat(t.toHexadecimal()).concat(o);default:throw new Error("Base ".concat(e," not supported "))}}function qv(t,e){if(typeof e=="function")return e(t);if(!t.isFinite())return t.isNaN()?"NaN":t.gt(0)?"Infinity":"-Infinity";var{notation:n,precision:r,wordSize:i}=Vd(e);switch(n){case"fixed":return JC(t,r);case"exponential":return Gv(t,r);case"engineering":return $C(t,r);case"bin":return rp(t,2,i);case"oct":return rp(t,8,i);case"hex":return rp(t,16,i);case"auto":{var o=Wv(e?.lowerExp,-3),s=Wv(e?.upperExp,5);if(t.isZero())return"0";var a,l=t.toSignificantDigits(r),u=l.e;return u>=o&&u<s?a=l.toFixed():a=Gv(t,r),a.replace(/((\.\d*?)(0+))($|e)/,function(){var c=arguments[2],f=arguments[4];return c!=="."?c+f:f})}default:throw new Error('Unknown notation "'+n+'". Choose "auto", "exponential", "fixed", "bin", "oct", or "hex.')}}function $C(t,e){var n=t.e,r=n%3===0?n:n<0?n-3-n%3:n-n%3,i=t.mul(Math.pow(10,-r)),o=i.toPrecision(e);if(o.includes("e")){var s=t.constructor;o=new s(o).toFixed()}return o+"e"+(n>=0?"+":"")+r.toString()}function Gv(t,e){return e!==void 0?t.toExponential(e-1):t.toExponential()}function JC(t,e){return t.toFixed(e)}function Wv(t,e){return ot(t)?t:st(t)?t.toNumber():e}function St(t,e){var n=KC(t,e);return e&&typeof e=="object"&&"truncate"in e&&n.length>e.truncate?n.substring(0,e.truncate-3)+"...":n}function KC(t,e){if(typeof t=="number")return xa(t,e);if(st(t))return qv(t,e);if(QC(t))return!e||e.fraction!=="decimal"?"".concat(t.s*t.n,"/").concat(t.d):t.toString();if(Array.isArray(t))return Zv(t,e);if(Kt(t))return Xv(t);if(typeof t=="function")return t.syntax?String(t.syntax):"function";if(t&&typeof t=="object"){if(typeof t.format=="function")return t.format(e);if(t&&t.toString(e)!=={}.toString())return t.toString(e);var n=Object.keys(t).map(r=>Xv(r)+": "+St(t[r],e));return"{"+n.join(", ")+"}"}return String(t)}function Xv(t){for(var e=String(t),n="",r=0;r<e.length;){var i=e.charAt(r);n+=i in Yv?Yv[i]:i,r++}return'"'+n+'"'}var Yv={'"':'\\"',"\\":"\\\\","\b":"\\b","\f":"\\f","\n":"\\n","\r":"\\r","	":"\\t"};function Zv(t,e){if(Array.isArray(t)){for(var n="[",r=t.length,i=0;i<r;i++)i!==0&&(n+=", "),n+=Zv(t[i],e);return n+="]",n}else return St(t,e)}function QC(t){return t&&typeof t=="object"&&typeof t.s=="bigint"&&typeof t.n=="bigint"&&typeof t.d=="bigint"||!1}function rt(t,e,n){if(!(this instanceof rt))throw new SyntaxError("Constructor must be called with the new operator");this.actual=t,this.expected=e,this.relation=n,this.message="Dimension mismatch ("+(Array.isArray(t)?"["+t.join(", ")+"]":t)+" "+(this.relation||"!=")+" "+(Array.isArray(e)?"["+e.join(", ")+"]":e)+")",this.stack=new Error().stack}rt.prototype=new RangeError;rt.prototype.constructor=RangeError;rt.prototype.name="DimensionError";rt.prototype.isDimensionError=!0;function sr(t,e,n){if(!(this instanceof sr))throw new SyntaxError("Constructor must be called with the new operator");this.index=t,arguments.length<3?(this.min=0,this.max=e):(this.min=e,this.max=n),this.min!==void 0&&this.index<this.min?this.message="Index out of range ("+this.index+" < "+this.min+")":this.max!==void 0&&this.index>=this.max?this.message="Index out of range ("+this.index+" > "+(this.max-1)+")":this.message="Index out of range ("+this.index+")",this.stack=new Error().stack}sr.prototype=new RangeError;sr.prototype.constructor=RangeError;sr.prototype.name="IndexError";sr.prototype.isIndexError=!0;function Pt(t){for(var e=[];Array.isArray(t);)e.push(t.length),t=t[0];return e}function $v(t,e,n){var r,i=t.length;if(i!==e[n])throw new rt(i,e[n]);if(n<e.length-1){var o=n+1;for(r=0;r<i;r++){var s=t[r];if(!Array.isArray(s))throw new rt(e.length-1,e.length,"<");$v(t[r],e,o)}}else for(r=0;r<i;r++)if(Array.isArray(t[r]))throw new rt(e.length+1,e.length,">")}function op(t,e){var n=e.length===0;if(n){if(Array.isArray(t))throw new rt(t.length,0)}else $v(t,e,0)}function At(t,e){if(t!==void 0){if(!ot(t)||!ht(t))throw new TypeError("Index must be an integer (value: "+t+")");if(t<0||typeof e=="number"&&t>=e)throw new sr(t,e)}}function Ma(t,e,n){if(!Array.isArray(e))throw new TypeError("Array expected");if(e.length===0)throw new Error("Resizing to scalar is not supported");e.forEach(function(i){if(!ot(i)||!ht(i)||i<0)throw new TypeError("Invalid size, must contain positive integers (size: "+St(e)+")")}),(ot(t)||st(t))&&(t=[t]);var r=n!==void 0?n:0;return ip(t,e,0,r),t}function ip(t,e,n,r){var i,o,s=t.length,a=e[n],l=Math.min(s,a);if(t.length=a,n<e.length-1){var u=n+1;for(i=0;i<l;i++)o=t[i],Array.isArray(o)||(o=[o],t[i]=o),ip(o,e,u,r);for(i=l;i<a;i++)o=[],t[i]=o,ip(o,e,u,r)}else{for(i=0;i<l;i++)for(;Array.isArray(t[i]);)t[i]=t[i][0];for(i=l;i<a;i++)t[i]=r}}function sp(t,e){var n=eT(t,!0),r=n.length;if(!Array.isArray(t)||!Array.isArray(e))throw new TypeError("Array expected");if(e.length===0)throw new rt(0,r,"!=");e=Sa(e,r);var i=Jv(e);if(r!==i)throw new rt(i,r,"!=");try{return jC(n,e)}catch(o){throw o instanceof rt?new rt(i,r,"!="):o}}function Sa(t,e){var n=Jv(t),r=t.slice(),i=-1,o=t.indexOf(i),s=t.indexOf(i,o+1)>=0;if(s)throw new Error("More than one wildcard in sizes");var a=o>=0,l=e%n===0;if(a)if(l)r[o]=-e/n;else throw new Error("Could not replace wildcard, since "+e+" is no multiple of "+-n);return r}function Jv(t){return t.reduce((e,n)=>e*n,1)}function jC(t,e){for(var n=t,r,i=e.length-1;i>0;i--){var o=e[i];r=[];for(var s=n.length/o,a=0;a<s;a++)r.push(n.slice(a*o,(a+1)*o));n=r}return n}function nf(t,e,n,r){var i=r||Pt(t);if(n)for(var o=0;o<n;o++)t=[t],i.unshift(1);for(t=Kv(t,e,0);i.length<e;)i.push(1);return t}function Kv(t,e,n){var r,i;if(Array.isArray(t)){var o=n+1;for(r=0,i=t.length;r<i;r++)t[r]=Kv(t[r],e,o)}else for(var s=n;s<e;s++)t=[t];return t}function eT(t){var e=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1;if(!Array.isArray(t))return t;if(typeof e!="boolean")throw new TypeError("Boolean expected for second argument of flatten");var n=[];return e?i(t):r(t),n;function r(o){for(var s=0;s<o.length;s++){var a=o[s];Array.isArray(a)?r(a):n.push(a)}}function i(o){if(Array.isArray(o[0]))for(var s=0;s<o.length;s++)i(o[s]);else for(var a=0;a<o.length;a++)n.push(o[a])}}function wa(t,e){for(var n,r=0,i=0;i<t.length;i++){var o=t[i],s=Array.isArray(o);if(i===0&&s&&(r=o.length),s&&o.length!==r)return;var a=s?wa(o,e):e(o);if(n===void 0)n=a;else if(n!==a)return"mixed"}return n}function Qv(t,e,n,r){if(r<n){if(t.length!==e.length)throw new rt(t.length,e.length);for(var i=[],o=0;o<t.length;o++)i[o]=Qv(t[o],e[o],n,r+1);return i}else return t.concat(e)}function ap(){var t=Array.prototype.slice.call(arguments,0,-1),e=Array.prototype.slice.call(arguments,-1);if(t.length===1)return t[0];if(t.length>1)return t.slice(1).reduce(function(n,r){return Qv(n,r,e,0)},t[0]);throw new Error("Wrong number of arguments in function concat")}function up(){for(var t=arguments.length,e=new Array(t),n=0;n<t;n++)e[n]=arguments[n];for(var r=e.map(h=>h.length),i=Math.max(...r),o=new Array(i).fill(null),s=0;s<e.length;s++)for(var a=e[s],l=r[s],u=0;u<l;u++){var c=i-l+u;a[u]>o[c]&&(o[c]=a[u])}for(var f=0;f<e.length;f++)jv(e[f],o);return o}function jv(t,e){for(var n=e.length,r=t.length,i=0;i<r;i++){var o=n-r+i;if(t[i]<e[o]&&t[i]>1||t[i]>e[o])throw new Error("shape mismatch: mismatch is found in arg with shape (".concat(t,") not possible to broadcast dimension ").concat(r," with size ").concat(t[i]," to size ").concat(e[o]))}}function ba(t,e){var n=Pt(t);if(Wn(n,e))return t;jv(n,e);var r=up(n,e),i=r.length,o=[...Array(i-n.length).fill(1),...n],s=nT(t);n.length<i&&(s=sp(s,o),n=Pt(s));for(var a=0;a<i;a++)n[a]<r[a]&&(s=tT(s,r[a],a),n=Pt(s));return s}function tT(t,e,n){return ap(...Array(e).fill(t),n)}function rf(t,e){if(!Array.isArray(t))throw new Error("Array expected");var n=Pt(t);if(e.length!==n.length)throw new rt(e.length,n.length);for(var r=0;r<e.length;r++)At(e[r],n[r]);return e.reduce((i,o)=>i[o],t)}function lp(t,e){var n=arguments.length>2&&arguments[2]!==void 0?arguments[2]:!1;if(t.length===0)return[];if(n)return o(t);var r=[];return i(t,0);function i(s,a){if(Array.isArray(s)){for(var l=s.length,u=Array(l),c=0;c<l;c++)r[a]=c,u[c]=i(s[c],a+1);return u}else return e(s,r.slice(0,a),t)}function o(s){if(Array.isArray(s)){for(var a=s.length,l=Array(a),u=0;u<a;u++)l[u]=o(s[u]);return l}else return e(s)}}function nT(t){return $o([],t)}var cp=Pa(Hc(),1);function is(t,e,n){var r=arguments.length>3&&arguments[3]!==void 0?arguments[3]:!1;if(cp.default.isTypedFunction(t)){var i;if(r)i=1;else{var o=(e.isMatrix?e.size():Pt(e)).map(()=>0),s=e.isMatrix?e.get(o):rf(e,o);i=oT(t,s,o,e)}var a;if(e.isMatrix&&e.dataType!=="mixed"&&e.dataType!==void 0){var l=rT(t,i);a=l!==void 0?l:t}else a=t;return i>=1&&i<=3?{isUnary:i===1,fn:function(){for(var c=arguments.length,f=new Array(c),h=0;h<c;h++)f[h]=arguments[h];return e_(a,f.slice(0,i),n,t.name)}}:{isUnary:!1,fn:function(){for(var c=arguments.length,f=new Array(c),h=0;h<c;h++)f[h]=arguments[h];return e_(a,f,n,t.name)}}}return r===void 0?{isUnary:iT(t),fn:t}:{isUnary:r,fn:t}}function rT(t,e){var n=[];if(Object.entries(t.signatures).forEach(r=>{var[i,o]=r;i.split(",").length===e&&n.push(o)}),n.length===1)return n[0]}function iT(t){if(t.length!==1)return!1;var e=t.toString();if(/arguments/.test(e))return!1;var n=e.match(/\(.*?\)/);return!/\.\.\./.test(n)}function oT(t,e,n,r){for(var i=[e,n,r],o=3;o>0;o--){var s=i.slice(0,o);if(cp.default.resolve(t,s)!==null)return o}}function e_(t,e,n,r){try{return t(...e)}catch(i){sT(i,e,n,r)}}function sT(t,e,n,r){var i;if(t instanceof TypeError&&((i=t.data)===null||i===void 0?void 0:i.category)==="wrongType"){var o=[];throw o.push("value: ".concat(Fn(e[0]))),e.length>=2&&o.push("index: ".concat(Fn(e[1]))),e.length>=3&&o.push("array: ".concat(Fn(e[2]))),new TypeError("Function ".concat(n," cannot apply callback arguments ")+"".concat(r,"(").concat(o.join(", "),") at index ").concat(JSON.stringify(e[1])))}else throw new TypeError("Function ".concat(n," cannot apply callback arguments ")+"to function ".concat(r,": ").concat(t.message))}var aT="DenseMatrix",uT=["Matrix"],fp=ve(aT,uT,t=>{var{Matrix:e}=t;function n(c,f){if(!(this instanceof n))throw new SyntaxError("Constructor must be called with the new operator");if(f&&!Kt(f))throw new Error("Invalid datatype: "+f);if(at(c))c.type==="DenseMatrix"?(this._data=ft(c._data),this._size=ft(c._size),this._datatype=f||c._datatype):(this._data=c.toArray(),this._size=c.size(),this._datatype=f||c._datatype);else if(c&&bt(c.data)&&bt(c.size))this._data=c.data,this._size=c.size,op(this._data,this._size),this._datatype=f||c.datatype;else if(bt(c))this._data=u(c),this._size=Pt(this._data),op(this._data,this._size),this._datatype=f;else{if(c)throw new TypeError("Unsupported type of data ("+Fn(c)+")");this._data=[],this._size=[0],this._datatype=f}}n.prototype=new e,n.prototype.createDenseMatrix=function(c,f){return new n(c,f)},Object.defineProperty(n,"name",{value:"DenseMatrix"}),n.prototype.constructor=n,n.prototype.type="DenseMatrix",n.prototype.isDenseMatrix=!0,n.prototype.getDataType=function(){return wa(this._data,Fn)},n.prototype.storage=function(){return"dense"},n.prototype.datatype=function(){return this._datatype},n.prototype.create=function(c,f){return new n(c,f)},n.prototype.subset=function(c,f,h){switch(arguments.length){case 1:return r(this,c);case 2:case 3:return o(this,c,f,h);default:throw new SyntaxError("Wrong number of arguments")}},n.prototype.get=function(c){return rf(this._data,c)},n.prototype.set=function(c,f,h){if(!bt(c))throw new TypeError("Array expected");if(c.length<this._size.length)throw new rt(c.length,this._size.length,"<");var d,x,p,g=c.map(function(b){return b+1});l(this,g,h);var m=this._data;for(d=0,x=c.length-1;d<x;d++)p=c[d],At(p,m.length),m=m[p];return p=c[c.length-1],At(p,m.length),m[p]=f,this};function r(c,f){if(!li(f))throw new TypeError("Invalid index");var h=f.isScalar();if(h)return c.get(f.min());var d=f.size();if(d.length!==c._size.length)throw new rt(d.length,c._size.length);for(var x=f.min(),p=f.max(),g=0,m=c._size.length;g<m;g++)At(x[g],c._size[g]),At(p[g],c._size[g]);var b=new n([]),v=i(c._data,f);return b._size=v.size,b._datatype=c._datatype,b._data=v.data,b}function i(c,f){var h=f.size().length-1,d=Array(h);return{data:x(c),size:d};function x(p){var g=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0,m=f.dimension(g);return d[g]=m.size()[0],g<h?m.map(b=>(At(b,p.length),x(p[b],g+1))).valueOf():m.map(b=>(At(b,p.length),p[b])).valueOf()}}function o(c,f,h,d){if(!f||f.isIndex!==!0)throw new TypeError("Invalid index");var x=f.size(),p=f.isScalar(),g;if(at(h)?(g=h.size(),h=h.valueOf()):g=Pt(h),p){if(g.length!==0)throw new TypeError("Scalar expected");c.set(f.min(),h,d)}else{if(!Wn(g,x))try{g.length===0?h=ba([h],x):h=ba(h,x),g=Pt(h)}catch{}if(x.length<c._size.length)throw new rt(x.length,c._size.length,"<");if(g.length<x.length){for(var m=0,b=0;x[m]===1&&g[m]===1;)m++;for(;x[m]===1;)b++,m++;h=nf(h,x.length,b,g)}if(!Wn(x,g))throw new rt(x,g,">");var v=f.max().map(function(_){return _+1});l(c,v,d),s(c._data,f,h)}return c}function s(c,f,h){var d=f.size().length-1;x(c,h);function x(p,g){var m=arguments.length>2&&arguments[2]!==void 0?arguments[2]:0,b=f.dimension(m);m<d?b.forEach((v,_)=>{At(v,p.length),x(p[v],g[_[0]],m+1)}):b.forEach((v,_)=>{At(v,p.length),p[v]=g[_[0]]})}}n.prototype.resize=function(c,f,h){if(!gr(c))throw new TypeError("Array or Matrix expected");var d=c.valueOf().map(p=>Array.isArray(p)&&p.length===1?p[0]:p),x=h?this.clone():this;return a(x,d,f)};function a(c,f,h){if(f.length===0){for(var d=c._data;bt(d);)d=d[0];return d}return c._size=f.slice(0),c._data=Ma(c._data,c._size,h),c}n.prototype.reshape=function(c,f){var h=f?this.clone():this;h._data=sp(h._data,c);var d=h._size.reduce((x,p)=>x*p);return h._size=Sa(c,d),h};function l(c,f,h){for(var d=c._size.slice(0),x=!1;d.length<f.length;)d.push(0),x=!0;for(var p=0,g=f.length;p<g;p++)f[p]>d[p]&&(d[p]=f[p],x=!0);x&&a(c,d,h)}n.prototype.clone=function(){var c=new n({data:ft(this._data),size:ft(this._size),datatype:this._datatype});return c},n.prototype.size=function(){return this._size.slice(0)},n.prototype.map=function(c){var f=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,h=arguments.length>2&&arguments[2]!==void 0?arguments[2]:!1,d=this,x=d._size.length-1;if(x<0)return d.clone();var p=is(c,d,"map",h),g=p.fn,m=d.create(void 0,d._datatype);if(m._size=d._size,h||p.isUnary)return m._data=E(d._data),m;if(x===0){for(var b=d.valueOf(),v=Array(b.length),_=0;_<b.length;_++)v[_]=g(b[_],[_],d);return m._data=v,m}var M=[];return m._data=y(d._data),m;function y(D){var S=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0,w=Array(D.length);if(S<x)for(var C=0;C<D.length;C++)M[S]=C,w[C]=y(D[C],S+1);else for(var F=0;F<D.length;F++)M[S]=F,w[F]=g(D[F],M.slice(),d);return w}function E(D){var S=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0,w=Array(D.length);if(S<x)for(var C=0;C<D.length;C++)w[C]=E(D[C],S+1);else for(var F=0;F<D.length;F++)w[F]=g(D[F]);return w}},n.prototype.forEach=function(c){var f=arguments.length>1&&arguments[1]!==void 0?arguments[1]:!1,h=arguments.length>2&&arguments[2]!==void 0?arguments[2]:!1,d=this,x=d._size.length-1;if(x<0)return;var p=is(c,d,"map",h),g=p.fn;if(h||p.isUnary){_(d._data);return}if(x===0){for(var m=0;m<d._data.length;m++)g(d._data[m],[m],d);return}var b=[];v(d._data);function v(M){var y=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;if(y<x)for(var E=0;E<M.length;E++)b[y]=E,v(M[E],y+1);else for(var D=0;D<M.length;D++)b[y]=D,g(M[D],b.slice(),d)}function _(M){var y=arguments.length>1&&arguments[1]!==void 0?arguments[1]:0;if(y<x)for(var E=0;E<M.length;E++)_(M[E],y+1);else for(var D=0;D<M.length;D++)g(M[D])}},n.prototype[Symbol.iterator]=function*(){var c=this._size.length-1;if(!(c<0)){if(c===0){for(var f=0;f<this._data.length;f++)yield{value:this._data[f],index:[f]};return}for(var h=Array(c+1).fill(0),d=this._size.reduce((b,v)=>b*v,1),x=0;x<d;x++){for(var p=this._data,g=0;g<c;g++)p=p[h[g]];yield{value:p[h[c]],index:h.slice()};for(var m=c;m>=0&&(h[m]++,!(h[m]<this._size[m]));m--)h[m]=0}}},n.prototype.rows=function(){var c=[],f=this.size();if(f.length!==2)throw new TypeError("Rows can only be returned for a 2D matrix.");var h=this._data;for(var d of h)c.push(new n([d],this._datatype));return c},n.prototype.columns=function(){var c=this,f=[],h=this.size();if(h.length!==2)throw new TypeError("Rows can only be returned for a 2D matrix.");for(var d=this._data,x=function(m){var b=d.map(v=>[v[m]]);f.push(new n(b,c._datatype))},p=0;p<h[1];p++)x(p);return f},n.prototype.toArray=function(){return ft(this._data)},n.prototype.valueOf=function(){return this._data},n.prototype.format=function(c){return St(this._data,c)},n.prototype.toString=function(){return St(this._data)},n.prototype.toJSON=function(){return{mathjs:"DenseMatrix",data:this._data,size:this._size,datatype:this._datatype}},n.prototype.diagonal=function(c){if(c){if(st(c)&&(c=c.toNumber()),!ot(c)||!ht(c))throw new TypeError("The parameter k must be an integer number")}else c=0;for(var f=c>0?c:0,h=c<0?-c:0,d=this._size[0],x=this._size[1],p=Math.min(d-h,x-f),g=[],m=0;m<p;m++)g[m]=this._data[m+h][m+f];return new n({data:g,size:[p],datatype:this._datatype})},n.diagonal=function(c,f,h,d){if(!bt(c))throw new TypeError("Array expected, size parameter");if(c.length!==2)throw new Error("Only two dimensions matrix are supported");if(c=c.map(function(E){if(st(E)&&(E=E.toNumber()),!ot(E)||!ht(E)||E<1)throw new Error("Size values must be positive integers");return E}),h){if(st(h)&&(h=h.toNumber()),!ot(h)||!ht(h))throw new TypeError("The parameter k must be an integer number")}else h=0;var x=h>0?h:0,p=h<0?-h:0,g=c[0],m=c[1],b=Math.min(g-p,m-x),v;if(bt(f)){if(f.length!==b)throw new Error("Invalid value array length");v=function(D){return f[D]}}else if(at(f)){var _=f.size();if(_.length!==1||_[0]!==b)throw new Error("Invalid matrix length");v=function(D){return f.get([D])}}else v=function(){return f};d||(d=st(v(0))?v(0).mul(0):0);var M=[];if(c.length>0){M=Ma(M,c,d);for(var y=0;y<b;y++)M[y+p][y+x]=v(y)}return new n({data:M,size:[g,m]})},n.fromJSON=function(c){return new n(c)},n.prototype.swapRows=function(c,f){if(!ot(c)||!ht(c)||!ot(f)||!ht(f))throw new Error("Row index must be positive integers");if(this._size.length!==2)throw new Error("Only two dimensional matrix is supported");return At(c,this._size[0]),At(f,this._size[0]),n._swapRows(c,f,this._data),this},n._swapRows=function(c,f,h){var d=h[c];h[c]=h[f],h[f]=d};function u(c){return at(c)?u(c.valueOf()):bt(c)?c.map(u):c}return n},{isClass:!0});function sn(t,e,n){if(!n)return at(t)?t.map(i=>e(i),!1,!0):lp(t,e,!0);var r=i=>i===0?i:e(i);return at(t)?t.map(i=>r(i),!1,!0):lp(t,r,!0)}var t_="isInteger",lT=["typed"],hp=ve(t_,lT,t=>{var{typed:e}=t;return e(t_,{number:ht,BigNumber:function(r){return r.isInt()},bigint:function(r){return!0},Fraction:function(r){return r.d===1n},"Array | Matrix":e.referToSelf(n=>r=>sn(r,n))})});var yn="number",Ur="number, number";function dp(t){return Math.abs(t)}dp.signature=yn;function pp(t,e){return t+e}pp.signature=Ur;function mp(t,e){return t-e}mp.signature=Ur;function gp(t,e){return t*e}gp.signature=Ur;function cT(t,e){return t/e}cT.signature=Ur;function xp(t){return-t}xp.signature=yn;function fT(t){return t}fT.signature=yn;function hT(t){return Sv(t)}hT.signature=yn;function dT(t){return t*t*t}dT.signature=yn;function pT(t){return Math.exp(t)}pT.signature=yn;function mT(t){return wv(t)}mT.signature=yn;function gT(t,e){if(!ht(t)||!ht(e))throw new Error("Parameters in function gcd must be integer numbers");for(var n;e!==0;)n=t%e,t=e,e=n;return t<0?-t:t}gT.signature=Ur;function xT(t,e){if(!ht(t)||!ht(e))throw new Error("Parameters in function lcm must be integer numbers");if(t===0||e===0)return 0;for(var n,r=t*e;e!==0;)n=e,e=t%n,t=n;return Math.abs(r/t)}xT.signature=Ur;function vT(t){return yv(t)}vT.signature=yn;function _T(t){return _v(t)}_T.signature=yn;function yT(t){return Mv(t)}yT.signature=yn;function MT(t,e){return e===0?t:t-e*Math.floor(t/e)}MT.signature=Ur;function ST(t){return vv(t)}ST.signature=yn;function wT(t){return Math.sqrt(t)}wT.signature=yn;function bT(t){return t*t}bT.signature=yn;function ET(t,e){var n,r,i,o=0,s=1,a=1,l=0;if(!ht(t)||!ht(e))throw new Error("Parameters in function xgcd must be integer numbers");for(;e;)r=Math.floor(t/e),i=t-r*e,n=o,o=s-r*o,s=n,n=a,a=l-r*a,l=n,t=e,e=i;var u;return t<0?u=[-t,-s,-l]:u=[t,t?s:0,l],u}ET.signature=Ur;function DT(t,e){return t*t<1&&e===1/0||t*t>1&&e===-1/0?0:Math.pow(t,e)}DT.signature=Ur;function AT(t){return Math.abs(t)}AT.signature=yn;function n_(t,e){var n=arguments.length>2&&arguments[2]!==void 0?arguments[2]:1e-9,r=arguments.length>3&&arguments[3]!==void 0?arguments[3]:0;if(n<=0)throw new Error("Relative tolerance must be greater than 0");if(r<0)throw new Error("Absolute tolerance must be at least 0");return t.isNaN()||e.isNaN()?!1:!t.isFinite()||!e.isFinite()?t.eq(e):t.eq(e)?!0:t.minus(e).abs().lte(t.constructor.max(t.constructor.max(t.abs(),e.abs()).mul(n),r))}var r_="isZero",CT=["typed","equalScalar"],vp=ve(r_,CT,t=>{var{typed:e,equalScalar:n}=t;return e(r_,{"number | BigNumber | Complex | Fraction":r=>n(r,0),bigint:r=>r===0n,Unit:e.referToSelf(r=>i=>e.find(r,i.valueType())(i.value)),"Array | Matrix":e.referToSelf(r=>i=>sn(i,r))})});function i_(t,e,n,r){return Qo(t.re,e.re,n,r)&&Qo(t.im,e.im,n,r)}var o_=ve("compareUnits",["typed"],t=>{var{typed:e}=t;return{"Unit, Unit":e.referToSelf(n=>(r,i)=>{if(!r.equalBase(i))throw new Error("Cannot compare units with different base");return e.find(n,[r.valueType(),i.valueType()])(r.value,i.value)})}});var of="equalScalar",TT=["typed","config"],_p=ve(of,TT,t=>{var{typed:e,config:n}=t,r=o_({typed:e});return e(of,{"boolean, boolean":function(o,s){return o===s},"number, number":function(o,s){return Qo(o,s,n.relTol,n.absTol)},"BigNumber, BigNumber":function(o,s){return o.eq(s)||n_(o,s,n.relTol,n.absTol)},"bigint, bigint":function(o,s){return o===s},"Fraction, Fraction":function(o,s){return o.equals(s)},"Complex, Complex":function(o,s){return i_(o,s,n.relTol,n.absTol)}},r)}),$k=ve(of,["typed","config"],t=>{var{typed:e,config:n}=t;return e(of,{"number, number":function(i,o){return Qo(i,o,n.relTol,n.absTol)}})});var RT="SparseMatrix",FT=["typed","equalScalar","Matrix"],yp=ve(RT,FT,t=>{var{typed:e,equalScalar:n,Matrix:r}=t;function i(p,g){if(!(this instanceof i))throw new SyntaxError("Constructor must be called with the new operator");if(g&&!Kt(g))throw new Error("Invalid datatype: "+g);if(at(p))o(this,p,g);else if(p&&bt(p.index)&&bt(p.ptr)&&bt(p.size))this._values=p.values,this._index=p.index,this._ptr=p.ptr,this._size=p.size,this._datatype=g||p.datatype;else if(bt(p))s(this,p,g);else{if(p)throw new TypeError("Unsupported type of data ("+Fn(p)+")");this._values=[],this._index=[],this._ptr=[0],this._size=[0,0],this._datatype=g}}function o(p,g,m){g.type==="SparseMatrix"?(p._values=g._values?ft(g._values):void 0,p._index=ft(g._index),p._ptr=ft(g._ptr),p._size=ft(g._size),p._datatype=m||g._datatype):s(p,g.valueOf(),m||g._datatype)}function s(p,g,m){p._values=[],p._index=[],p._ptr=[],p._datatype=m;var b=g.length,v=0,_=n,M=0;if(Kt(m)&&(_=e.find(n,[m,m])||n,M=e.convert(0,m)),b>0){var y=0;do{p._ptr.push(p._index.length);for(var E=0;E<b;E++){var D=g[E];if(bt(D)){if(y===0&&v<D.length&&(v=D.length),y<D.length){var S=D[y];_(S,M)||(p._values.push(S),p._index.push(E))}}else y===0&&v<1&&(v=1),_(D,M)||(p._values.push(D),p._index.push(E))}y++}while(y<v)}p._ptr.push(p._index.length),p._size=[b,v]}i.prototype=new r,i.prototype.createSparseMatrix=function(p,g){return new i(p,g)},Object.defineProperty(i,"name",{value:"SparseMatrix"}),i.prototype.constructor=i,i.prototype.type="SparseMatrix",i.prototype.isSparseMatrix=!0,i.prototype.getDataType=function(){return wa(this._values,Fn)},i.prototype.storage=function(){return"sparse"},i.prototype.datatype=function(){return this._datatype},i.prototype.create=function(p,g){return new i(p,g)},i.prototype.density=function(){var p=this._size[0],g=this._size[1];return p!==0&&g!==0?this._index.length/(p*g):0},i.prototype.subset=function(p,g,m){if(!this._values)throw new Error("Cannot invoke subset on a Pattern only matrix");switch(arguments.length){case 1:return a(this,p);case 2:case 3:return l(this,p,g,m);default:throw new SyntaxError("Wrong number of arguments")}};function a(p,g){if(!li(g))throw new TypeError("Invalid index");var m=g.isScalar();if(m)return p.get(g.min());var b=g.size();if(b.length!==p._size.length)throw new rt(b.length,p._size.length);var v,_,M,y,E=g.min(),D=g.max();for(v=0,_=p._size.length;v<_;v++)At(E[v],p._size[v]),At(D[v],p._size[v]);var S=p._values,w=p._index,C=p._ptr,F=g.dimension(0),O=g.dimension(1),U=[],z=[];F.forEach(function(ne,se){z[ne]=se[0],U[ne]=!0});var B=S?[]:void 0,J=[],H=[];return O.forEach(function(ne){for(H.push(J.length),M=C[ne],y=C[ne+1];M<y;M++)v=w[M],U[v]===!0&&(J.push(z[v]),B&&B.push(S[M]))}),H.push(J.length),new i({values:B,index:J,ptr:H,size:b,datatype:p._datatype})}function l(p,g,m,b){if(!g||g.isIndex!==!0)throw new TypeError("Invalid index");var v=g.size(),_=g.isScalar(),M;if(at(m)?(M=m.size(),m=m.toArray()):M=Pt(m),_){if(M.length!==0)throw new TypeError("Scalar expected");p.set(g.min(),m,b)}else{if(v.length!==1&&v.length!==2)throw new rt(v.length,p._size.length,"<");if(M.length<v.length){for(var y=0,E=0;v[y]===1&&M[y]===1;)y++;for(;v[y]===1;)E++,y++;m=nf(m,v.length,E,M)}if(!Wn(v,M))throw new rt(v,M,">");if(v.length===1){var D=g.dimension(0);D.forEach(function(C,F){At(C),p.set([C,0],m[F[0]],b)})}else{var S=g.dimension(0),w=g.dimension(1);S.forEach(function(C,F){At(C),w.forEach(function(O,U){At(O),p.set([C,O],m[F[0]][U[0]],b)})})}}return p}i.prototype.get=function(p){if(!bt(p))throw new TypeError("Array expected");if(p.length!==this._size.length)throw new rt(p.length,this._size.length);if(!this._values)throw new Error("Cannot invoke get on a Pattern only matrix");var g=p[0],m=p[1];At(g,this._size[0]),At(m,this._size[1]);var b=u(g,this._ptr[m],this._ptr[m+1],this._index);return b<this._ptr[m+1]&&this._index[b]===g?this._values[b]:0},i.prototype.set=function(p,g,m){if(!bt(p))throw new TypeError("Array expected");if(p.length!==this._size.length)throw new rt(p.length,this._size.length);if(!this._values)throw new Error("Cannot invoke set on a Pattern only matrix");var b=p[0],v=p[1],_=this._size[0],M=this._size[1],y=n,E=0;Kt(this._datatype)&&(y=e.find(n,[this._datatype,this._datatype])||n,E=e.convert(0,this._datatype)),(b>_-1||v>M-1)&&(h(this,Math.max(b+1,_),Math.max(v+1,M),m),_=this._size[0],M=this._size[1]),At(b,_),At(v,M);var D=u(b,this._ptr[v],this._ptr[v+1],this._index);return D<this._ptr[v+1]&&this._index[D]===b?y(g,E)?c(D,v,this._values,this._index,this._ptr):this._values[D]=g:y(g,E)||f(D,b,v,g,this._values,this._index,this._ptr),this};function u(p,g,m,b){if(m-g===0)return m;for(var v=g;v<m;v++)if(b[v]===p)return v;return g}function c(p,g,m,b,v){m.splice(p,1),b.splice(p,1);for(var _=g+1;_<v.length;_++)v[_]--}function f(p,g,m,b,v,_,M){v.splice(p,0,b),_.splice(p,0,g);for(var y=m+1;y<M.length;y++)M[y]++}i.prototype.resize=function(p,g,m){if(!gr(p))throw new TypeError("Array or Matrix expected");var b=p.valueOf().map(_=>Array.isArray(_)&&_.length===1?_[0]:_);if(b.length!==2)throw new Error("Only two dimensions matrix are supported");b.forEach(function(_){if(!ot(_)||!ht(_)||_<0)throw new TypeError("Invalid size, must contain positive integers (size: "+St(b)+")")});var v=m?this.clone():this;return h(v,b[0],b[1],g)};function h(p,g,m,b){var v=b||0,_=n,M=0;Kt(p._datatype)&&(_=e.find(n,[p._datatype,p._datatype])||n,M=e.convert(0,p._datatype),v=e.convert(v,p._datatype));var y=!_(v,M),E=p._size[0],D=p._size[1],S,w,C;if(m>D){for(w=D;w<m;w++)if(p._ptr[w]=p._values.length,y)for(S=0;S<E;S++)p._values.push(v),p._index.push(S);p._ptr[m]=p._values.length}else m<D&&(p._ptr.splice(m+1,D-m),p._values.splice(p._ptr[m],p._values.length),p._index.splice(p._ptr[m],p._index.length));if(D=m,g>E){if(y){var F=0;for(w=0;w<D;w++){p._ptr[w]=p._ptr[w]+F,C=p._ptr[w+1]+F;var O=0;for(S=E;S<g;S++,O++)p._values.splice(C+O,0,v),p._index.splice(C+O,0,S),F++}p._ptr[D]=p._values.length}}else if(g<E){var U=0;for(w=0;w<D;w++){p._ptr[w]=p._ptr[w]-U;var z=p._ptr[w],B=p._ptr[w+1]-U;for(C=z;C<B;C++)S=p._index[C],S>g-1&&(p._values.splice(C,1),p._index.splice(C,1),U++)}p._ptr[w]=p._values.length}return p._size[0]=g,p._size[1]=m,p}i.prototype.reshape=function(p,g){if(!bt(p))throw new TypeError("Array expected");if(p.length!==2)throw new Error("Sparse matrices can only be reshaped in two dimensions");p.forEach(function(ne){if(!ot(ne)||!ht(ne)||ne<=-2||ne===0)throw new TypeError("Invalid size, must contain positive integers or -1 (size: "+St(p)+")")});var m=this._size[0]*this._size[1];p=Sa(p,m);var b=p[0]*p[1];if(m!==b)throw new Error("Reshaping sparse matrix will result in the wrong number of elements");var v=g?this.clone():this;if(this._size[0]===p[0]&&this._size[1]===p[1])return v;for(var _=[],M=0;M<v._ptr.length;M++)for(var y=0;y<v._ptr[M+1]-v._ptr[M];y++)_.push(M);for(var E=v._values.slice(),D=v._index.slice(),S=0;S<v._index.length;S++){var w=D[S],C=_[S],F=w*v._size[1]+C;_[S]=F%p[1],D[S]=Math.floor(F/p[1])}v._values.length=0,v._index.length=0,v._ptr.length=p[1]+1,v._size=p.slice();for(var O=0;O<v._ptr.length;O++)v._ptr[O]=0;for(var U=0;U<E.length;U++){var z=D[U],B=_[U],J=E[U],H=u(z,v._ptr[B],v._ptr[B+1],v._index);f(H,z,B,J,v._values,v._index,v._ptr)}return v},i.prototype.clone=function(){var p=new i({values:this._values?ft(this._values):void 0,index:ft(this._index),ptr:ft(this._ptr),size:ft(this._size),datatype:this._datatype});return p},i.prototype.size=function(){return this._size.slice(0)},i.prototype.map=function(p,g){if(!this._values)throw new Error("Cannot invoke map on a Pattern only matrix");var m=this,b=this._size[0],v=this._size[1],_=is(p,m,"map"),M=function(E,D,S){return _.fn(E,[D,S],m)};return d(this,0,b-1,0,v-1,M,g)};function d(p,g,m,b,v,_,M){var y=[],E=[],D=[],S=n,w=0;Kt(p._datatype)&&(S=e.find(n,[p._datatype,p._datatype])||n,w=e.convert(0,p._datatype));for(var C=function(ze,Ze,ke){var re=_(ze,Ze,ke);S(re,w)||(y.push(re),E.push(Ze))},F=b;F<=v;F++){D.push(y.length);var O=p._ptr[F],U=p._ptr[F+1];if(M)for(var z=O;z<U;z++){var B=p._index[z];B>=g&&B<=m&&C(p._values[z],B-g,F-b)}else{for(var J={},H=O;H<U;H++){var ne=p._index[H];J[ne]=p._values[H]}for(var se=g;se<=m;se++){var ge=se in J?J[se]:0;C(ge,se-g,F-b)}}}return D.push(y.length),new i({values:y,index:E,ptr:D,size:[m-g+1,v-b+1]})}i.prototype.forEach=function(p,g){if(!this._values)throw new Error("Cannot invoke forEach on a Pattern only matrix");for(var m=this,b=this._size[0],v=this._size[1],_=is(p,m,"forEach"),M=0;M<v;M++){var y=this._ptr[M],E=this._ptr[M+1];if(g)for(var D=y;D<E;D++){var S=this._index[D];_.fn(this._values[D],[S,M],m)}else{for(var w={},C=y;C<E;C++){var F=this._index[C];w[F]=this._values[C]}for(var O=0;O<b;O++){var U=O in w?w[O]:0;_.fn(U,[O,M],m)}}}},i.prototype[Symbol.iterator]=function*(){if(!this._values)throw new Error("Cannot iterate a Pattern only matrix");for(var p=this._size[1],g=0;g<p;g++)for(var m=this._ptr[g],b=this._ptr[g+1],v=m;v<b;v++){var _=this._index[v];yield{value:this._values[v],index:[_,g]}}},i.prototype.toArray=function(){return x(this._values,this._index,this._ptr,this._size,!0)},i.prototype.valueOf=function(){return x(this._values,this._index,this._ptr,this._size,!1)};function x(p,g,m,b,v){var _=b[0],M=b[1],y=[],E,D;for(E=0;E<_;E++)for(y[E]=[],D=0;D<M;D++)y[E][D]=0;for(D=0;D<M;D++)for(var S=m[D],w=m[D+1],C=S;C<w;C++)E=g[C],y[E][D]=p?v?ft(p[C]):p[C]:1;return y}return i.prototype.format=function(p){for(var g=this._size[0],m=this._size[1],b=this.density(),v="Sparse Matrix ["+St(g,p)+" x "+St(m,p)+"] density: "+St(b,p)+`
`,_=0;_<m;_++)for(var M=this._ptr[_],y=this._ptr[_+1],E=M;E<y;E++){var D=this._index[E];v+=`
    (`+St(D,p)+", "+St(_,p)+") ==> "+(this._values?St(this._values[E],p):"X")}return v},i.prototype.toString=function(){return St(this.toArray())},i.prototype.toJSON=function(){return{mathjs:"SparseMatrix",values:this._values,index:this._index,ptr:this._ptr,size:this._size,datatype:this._datatype}},i.prototype.diagonal=function(p){if(p){if(st(p)&&(p=p.toNumber()),!ot(p)||!ht(p))throw new TypeError("The parameter k must be an integer number")}else p=0;var g=p>0?p:0,m=p<0?-p:0,b=this._size[0],v=this._size[1],_=Math.min(b-m,v-g),M=[],y=[],E=[];E[0]=0;for(var D=g;D<v&&M.length<_;D++)for(var S=this._ptr[D],w=this._ptr[D+1],C=S;C<w;C++){var F=this._index[C];if(F===D-g+m){M.push(this._values[C]),y[M.length-1]=F-m;break}}return E.push(M.length),new i({values:M,index:y,ptr:E,size:[_,1]})},i.fromJSON=function(p){return new i(p)},i.diagonal=function(p,g,m,b,v){if(!bt(p))throw new TypeError("Array expected, size parameter");if(p.length!==2)throw new Error("Only two dimensions matrix are supported");if(p=p.map(function(ne){if(st(ne)&&(ne=ne.toNumber()),!ot(ne)||!ht(ne)||ne<1)throw new Error("Size values must be positive integers");return ne}),m){if(st(m)&&(m=m.toNumber()),!ot(m)||!ht(m))throw new TypeError("The parameter k must be an integer number")}else m=0;var _=n,M=0;Kt(v)&&(_=e.find(n,[v,v])||n,M=e.convert(0,v));var y=m>0?m:0,E=m<0?-m:0,D=p[0],S=p[1],w=Math.min(D-E,S-y),C;if(bt(g)){if(g.length!==w)throw new Error("Invalid value array length");C=function(se){return g[se]}}else if(at(g)){var F=g.size();if(F.length!==1||F[0]!==w)throw new Error("Invalid matrix length");C=function(se){return g.get([se])}}else C=function(){return g};for(var O=[],U=[],z=[],B=0;B<S;B++){z.push(O.length);var J=B-y;if(J>=0&&J<w){var H=C(J);_(H,M)||(U.push(J+E),O.push(H))}}return z.push(O.length),new i({values:O,index:U,ptr:z,size:[D,S]})},i.prototype.swapRows=function(p,g){if(!ot(p)||!ht(p)||!ot(g)||!ht(g))throw new Error("Row index must be positive integers");if(this._size.length!==2)throw new Error("Only two dimensional matrix is supported");return At(p,this._size[0]),At(g,this._size[0]),i._swapRows(p,g,this._size[1],this._values,this._index,this._ptr),this},i._forEachRow=function(p,g,m,b,v){for(var _=b[p],M=b[p+1],y=_;y<M;y++)v(m[y],g[y])},i._swapRows=function(p,g,m,b,v,_){for(var M=0;M<m;M++){var y=_[M],E=_[M+1],D=u(p,y,E,v),S=u(g,y,E,v);if(D<E&&S<E&&v[D]===p&&v[S]===g){if(b){var w=b[D];b[D]=b[S],b[S]=w}continue}if(D<E&&v[D]===p&&(S>=E||v[S]!==g)){var C=b?b[D]:void 0;v.splice(S,0,g),b&&b.splice(S,0,C),v.splice(S<=D?D+1:D,1),b&&b.splice(S<=D?D+1:D,1);continue}if(S<E&&v[S]===g&&(D>=E||v[D]!==p)){var F=b?b[S]:void 0;v.splice(D,0,p),b&&b.splice(D,0,F),v.splice(D<=S?S+1:S,1),b&&b.splice(D<=S?S+1:S,1)}}},i},{isClass:!0});var PT="number",IT=["typed"];function NT(t){var e=t.match(/(0[box])([0-9a-fA-F]*)\.([0-9a-fA-F]*)/);if(e){var n={"0b":2,"0o":8,"0x":16}[e[1]],r=e[2],i=e[3];return{input:t,radix:n,integerPart:r,fractionalPart:i}}else return null}function LT(t){for(var e=parseInt(t.integerPart,t.radix),n=0,r=0;r<t.fractionalPart.length;r++){var i=parseInt(t.fractionalPart[r],t.radix);n+=i/Math.pow(t.radix,r+1)}var o=e+n;if(isNaN(o))throw new SyntaxError('String "'+t.input+'" is not a valid number');return o}var Mp=ve(PT,IT,t=>{var{typed:e}=t,n=e("number",{"":function(){return 0},number:function(i){return i},string:function(i){if(i==="NaN")return NaN;var o=NT(i);if(o)return LT(o);var s=0,a=i.match(/(0[box][0-9a-fA-F]*)i([0-9]*)/);a&&(s=Number(a[2]),i=a[1]);var l=Number(i);if(isNaN(l))throw new SyntaxError('String "'+i+'" is not a valid number');if(a){if(l>2**s-1)throw new SyntaxError('String "'.concat(i,'" is out of range'));l>=2**(s-1)&&(l=l-2**s)}return l},BigNumber:function(i){return i.toNumber()},bigint:function(i){return Number(i)},Fraction:function(i){return i.valueOf()},Unit:e.referToSelf(r=>i=>{var o=i.clone();return o.value=r(i.value),o}),null:function(i){return 0},"Unit, string | Unit":function(i,o){return i.toNumber(o)},"Array | Matrix":e.referToSelf(r=>i=>sn(i,r))});return n.fromJSON=function(r){return parseFloat(r.value)},n});var BT="bignumber",UT=["typed","BigNumber"],Sp=ve(BT,UT,t=>{var{typed:e,BigNumber:n}=t;return e("bignumber",{"":function(){return new n(0)},number:function(i){return new n(i+"")},string:function(i){var o=i.match(/(0[box][0-9a-fA-F]*)i([0-9]*)/);if(o){var s=o[2],a=n(o[1]),l=new n(2).pow(Number(s));if(a.gt(l.sub(1)))throw new SyntaxError('String "'.concat(i,'" is out of range'));var u=new n(2).pow(Number(s)-1);return a.gte(u)?a.sub(l):a}return new n(i)},BigNumber:function(i){return i},bigint:function(i){return new n(i.toString())},Unit:e.referToSelf(r=>i=>{var o=i.clone();return o.value=r(i.value),o}),Fraction:function(i){return new n(String(i.n)).div(String(i.d)).times(String(i.s))},null:function(i){return new n(0)},"Array | Matrix":e.referToSelf(r=>i=>sn(i,r))})});var OT="fraction",zT=["typed","Fraction"],wp=ve(OT,zT,t=>{var{typed:e,Fraction:n}=t;return e("fraction",{number:function(i){if(!isFinite(i)||isNaN(i))throw new Error(i+" cannot be represented as a fraction");return new n(i)},string:function(i){return new n(i)},"number, number":function(i,o){return new n(i,o)},"bigint, bigint":function(i,o){return new n(i,o)},null:function(i){return new n(0)},BigNumber:function(i){return new n(i.toString())},bigint:function(i){return new n(i.toString())},Fraction:function(i){return i},Unit:e.referToSelf(r=>i=>{var o=i.clone();return o.value=r(i.value),o}),Object:function(i){return new n(i)},"Array | Matrix":e.referToSelf(r=>i=>sn(i,r))})});var s_="matrix",kT=["typed","Matrix","DenseMatrix","SparseMatrix"],bp=ve(s_,kT,t=>{var{typed:e,Matrix:n,DenseMatrix:r,SparseMatrix:i}=t;return e(s_,{"":function(){return o([])},string:function(a){return o([],a)},"string, string":function(a,l){return o([],a,l)},Array:function(a){return o(a)},Matrix:function(a){return o(a,a.storage())},"Array | Matrix, string":o,"Array | Matrix, string, string":o});function o(s,a,l){if(a==="dense"||a==="default"||a===void 0)return new r(s,l);if(a==="sparse")return new i(s,l);throw new TypeError("Unknown matrix type "+JSON.stringify(a)+".")}});var a_="unaryMinus",VT=["typed"],Ep=ve(a_,VT,t=>{var{typed:e}=t;return e(a_,{number:xp,"Complex | BigNumber | Fraction":n=>n.neg(),bigint:n=>-n,Unit:e.referToSelf(n=>r=>{var i=r.clone();return i.value=e.find(n,i.valueType())(r.value),i}),"Array | Matrix":e.referToSelf(n=>r=>sn(r,n,!0))})});var u_="abs",HT=["typed"],Dp=ve(u_,HT,t=>{var{typed:e}=t;return e(u_,{number:dp,"Complex | BigNumber | Fraction | Unit":n=>n.abs(),bigint:n=>n<0n?-n:n,"Array | Matrix":e.referToSelf(n=>r=>sn(r,n,!0))})});var l_="addScalar",GT=["typed"],Ap=ve(l_,GT,t=>{var{typed:e}=t;return e(l_,{"number, number":pp,"Complex, Complex":function(r,i){return r.add(i)},"BigNumber, BigNumber":function(r,i){return r.plus(i)},"bigint, bigint":function(r,i){return r+i},"Fraction, Fraction":function(r,i){return r.add(i)},"Unit, Unit":e.referToSelf(n=>(r,i)=>{if(r.value===null||r.value===void 0)throw new Error("Parameter x contains a unit with undefined value");if(i.value===null||i.value===void 0)throw new Error("Parameter y contains a unit with undefined value");if(!r.equalBase(i))throw new Error("Units do not match");var o=r.clone();return o.value=e.find(n,[o.valueType(),i.valueType()])(o.value,i.value),o.fixPrefix=!1,o})})});var c_="subtractScalar",WT=["typed"],Cp=ve(c_,WT,t=>{var{typed:e}=t;return e(c_,{"number, number":mp,"Complex, Complex":function(r,i){return r.sub(i)},"BigNumber, BigNumber":function(r,i){return r.minus(i)},"bigint, bigint":function(r,i){return r-i},"Fraction, Fraction":function(r,i){return r.sub(i)},"Unit, Unit":e.referToSelf(n=>(r,i)=>{if(r.value===null||r.value===void 0)throw new Error("Parameter x contains a unit with undefined value");if(i.value===null||i.value===void 0)throw new Error("Parameter y contains a unit with undefined value");if(!r.equalBase(i))throw new Error("Units do not match");var o=r.clone();return o.value=e.find(n,[o.valueType(),i.valueType()])(o.value,i.value),o.fixPrefix=!1,o})})});var qT="matAlgo11xS0s",XT=["typed","equalScalar"],f_=ve(qT,XT,t=>{var{typed:e,equalScalar:n}=t;return function(i,o,s,a){var l=i._values,u=i._index,c=i._ptr,f=i._size,h=i._datatype;if(!l)throw new Error("Cannot perform operation on Pattern Sparse Matrix and Scalar value");var d=f[0],x=f[1],p,g=n,m=0,b=s;typeof h=="string"&&(p=h,g=e.find(n,[p,p]),m=e.convert(0,p),o=e.convert(o,p),b=e.find(s,[p,p]));for(var v=[],_=[],M=[],y=0;y<x;y++){M[y]=_.length;for(var E=c[y],D=c[y+1],S=E;S<D;S++){var w=u[S],C=a?b(o,l[S]):b(l[S],o);g(C,m)||(_.push(w),v.push(C))}}return M[x]=_.length,i.createSparseMatrix({values:v,index:_,ptr:M,size:[d,x],datatype:p})}});var YT="matAlgo14xDs",ZT=["typed"],sf=ve(YT,ZT,t=>{var{typed:e}=t;return function(i,o,s,a){var l=i._data,u=i._size,c=i._datatype,f,h=s;typeof c=="string"&&(f=c,o=e.convert(o,f),h=e.find(s,[f,f]));var d=u.length>0?n(h,0,u,u[0],l,o,a):[];return i.createDenseMatrix({data:d,size:ft(u),datatype:f})};function n(r,i,o,s,a,l,u){var c=[];if(i===o.length-1)for(var f=0;f<s;f++)c[f]=u?r(l,a[f]):r(a[f],l);else for(var h=0;h<s;h++)c[h]=n(r,i+1,o,o[i+1],a[h],l,u);return c}});var $T="matAlgo13xDD",JT=["typed"],h_=ve($T,JT,t=>{var{typed:e}=t;return function(i,o,s){var a=i._data,l=i._size,u=i._datatype,c=o._data,f=o._size,h=o._datatype,d=[];if(l.length!==f.length)throw new rt(l.length,f.length);for(var x=0;x<l.length;x++){if(l[x]!==f[x])throw new RangeError("Dimension mismatch. Matrix A ("+l+") must match Matrix B ("+f+")");d[x]=l[x]}var p,g=s;typeof u=="string"&&u===h&&(p=u,g=e.find(s,[p,p]));var m=d.length>0?n(g,0,d,d[0],a,c):[];return i.createDenseMatrix({data:m,size:d,datatype:p})};function n(r,i,o,s,a,l){var u=[];if(i===o.length-1)for(var c=0;c<s;c++)u[c]=r(a[c],l[c]);else for(var f=0;f<s;f++)u[f]=n(r,i+1,o,o[i+1],a[f],l[f]);return u}});function Ht(t,e){if(Wn(t.size(),e.size()))return[t,e];var n=up(t.size(),e.size());return[t,e].map(r=>KT(r,n))}function KT(t,e){return Wn(t.size(),e)?t:t.create(ba(t.valueOf(),e),t.datatype())}var QT="matrixAlgorithmSuite",jT=["typed","matrix"],d_=ve(QT,jT,t=>{var{typed:e,matrix:n}=t,r=h_({typed:e}),i=sf({typed:e});return function(s){var a=s.elop,l=s.SD||s.DS,u;a?(u={"DenseMatrix, DenseMatrix":(d,x)=>r(...Ht(d,x),a),"Array, Array":(d,x)=>r(...Ht(n(d),n(x)),a).valueOf(),"Array, DenseMatrix":(d,x)=>r(...Ht(n(d),x),a),"DenseMatrix, Array":(d,x)=>r(...Ht(d,n(x)),a)},s.SS&&(u["SparseMatrix, SparseMatrix"]=(d,x)=>s.SS(...Ht(d,x),a,!1)),s.DS&&(u["DenseMatrix, SparseMatrix"]=(d,x)=>s.DS(...Ht(d,x),a,!1),u["Array, SparseMatrix"]=(d,x)=>s.DS(...Ht(n(d),x),a,!1)),l&&(u["SparseMatrix, DenseMatrix"]=(d,x)=>l(...Ht(x,d),a,!0),u["SparseMatrix, Array"]=(d,x)=>l(...Ht(n(x),d),a,!0))):(u={"DenseMatrix, DenseMatrix":e.referToSelf(d=>(x,p)=>r(...Ht(x,p),d)),"Array, Array":e.referToSelf(d=>(x,p)=>r(...Ht(n(x),n(p)),d).valueOf()),"Array, DenseMatrix":e.referToSelf(d=>(x,p)=>r(...Ht(n(x),p),d)),"DenseMatrix, Array":e.referToSelf(d=>(x,p)=>r(...Ht(x,n(p)),d))},s.SS&&(u["SparseMatrix, SparseMatrix"]=e.referToSelf(d=>(x,p)=>s.SS(...Ht(x,p),d,!1))),s.DS&&(u["DenseMatrix, SparseMatrix"]=e.referToSelf(d=>(x,p)=>s.DS(...Ht(x,p),d,!1)),u["Array, SparseMatrix"]=e.referToSelf(d=>(x,p)=>s.DS(...Ht(n(x),p),d,!1))),l&&(u["SparseMatrix, DenseMatrix"]=e.referToSelf(d=>(x,p)=>l(...Ht(p,x),d,!0)),u["SparseMatrix, Array"]=e.referToSelf(d=>(x,p)=>l(...Ht(n(p),x),d,!0))));var c=s.scalar||"any",f=s.Ds||s.Ss;f&&(a?(u["DenseMatrix,"+c]=(d,x)=>i(d,x,a,!1),u[c+", DenseMatrix"]=(d,x)=>i(x,d,a,!0),u["Array,"+c]=(d,x)=>i(n(d),x,a,!1).valueOf(),u[c+", Array"]=(d,x)=>i(n(x),d,a,!0).valueOf()):(u["DenseMatrix,"+c]=e.referToSelf(d=>(x,p)=>i(x,p,d,!1)),u[c+", DenseMatrix"]=e.referToSelf(d=>(x,p)=>i(p,x,d,!0)),u["Array,"+c]=e.referToSelf(d=>(x,p)=>i(n(x),p,d,!1).valueOf()),u[c+", Array"]=e.referToSelf(d=>(x,p)=>i(n(p),x,d,!0).valueOf())));var h=s.sS!==void 0?s.sS:s.Ss;return a?(s.Ss&&(u["SparseMatrix,"+c]=(d,x)=>s.Ss(d,x,a,!1)),h&&(u[c+", SparseMatrix"]=(d,x)=>h(x,d,a,!0))):(s.Ss&&(u["SparseMatrix,"+c]=e.referToSelf(d=>(x,p)=>s.Ss(x,p,d,!1))),h&&(u[c+", SparseMatrix"]=e.referToSelf(d=>(x,p)=>h(p,x,d,!0)))),a&&a.signatures&&av(u,a.signatures),u}});var e2="matAlgo01xDSid",t2=["typed"],p_=ve(e2,t2,t=>{var{typed:e}=t;return function(r,i,o,s){var a=r._data,l=r._size,u=r._datatype||r.getDataType(),c=i._values,f=i._index,h=i._ptr,d=i._size,x=i._datatype||i._data===void 0?i._datatype:i.getDataType();if(l.length!==d.length)throw new rt(l.length,d.length);if(l[0]!==d[0]||l[1]!==d[1])throw new RangeError("Dimension mismatch. Matrix A ("+l+") must match Matrix B ("+d+")");if(!c)throw new Error("Cannot perform operation on Dense Matrix and Pattern Sparse Matrix");var p=l[0],g=l[1],m=typeof u=="string"&&u!=="mixed"&&u===x?u:void 0,b=m?e.find(o,[m,m]):o,v,_,M=[];for(v=0;v<p;v++)M[v]=[];var y=[],E=[];for(_=0;_<g;_++){for(var D=_+1,S=h[_],w=h[_+1],C=S;C<w;C++)v=f[C],y[v]=s?b(c[C],a[v][_]):b(a[v][_],c[C]),E[v]=D;for(v=0;v<p;v++)E[v]===D?M[v][_]=y[v]:M[v][_]=a[v][_]}return r.createDenseMatrix({data:M,size:[p,g],datatype:u===r._datatype&&x===i._datatype?m:void 0})}});var n2="matAlgo04xSidSid",r2=["typed","equalScalar"],m_=ve(n2,r2,t=>{var{typed:e,equalScalar:n}=t;return function(i,o,s){var a=i._values,l=i._index,u=i._ptr,c=i._size,f=i._datatype||i._data===void 0?i._datatype:i.getDataType(),h=o._values,d=o._index,x=o._ptr,p=o._size,g=o._datatype||o._data===void 0?o._datatype:o.getDataType();if(c.length!==p.length)throw new rt(c.length,p.length);if(c[0]!==p[0]||c[1]!==p[1])throw new RangeError("Dimension mismatch. Matrix A ("+c+") must match Matrix B ("+p+")");var m=c[0],b=c[1],v,_=n,M=0,y=s;typeof f=="string"&&f===g&&f!=="mixed"&&(v=f,_=e.find(n,[v,v]),M=e.convert(0,v),y=e.find(s,[v,v]));var E=a&&h?[]:void 0,D=[],S=[],w=a&&h?[]:void 0,C=a&&h?[]:void 0,F=[],O=[],U,z,B,J,H;for(z=0;z<b;z++){S[z]=D.length;var ne=z+1;for(J=u[z],H=u[z+1],B=J;B<H;B++)U=l[B],D.push(U),F[U]=ne,w&&(w[U]=a[B]);for(J=x[z],H=x[z+1],B=J;B<H;B++)if(U=d[B],F[U]===ne){if(w){var se=y(w[U],h[B]);_(se,M)?F[U]=null:w[U]=se}}else D.push(U),O[U]=ne,C&&(C[U]=h[B]);if(w&&C)for(B=S[z];B<D.length;)U=D[B],F[U]===ne?(E[B]=w[U],B++):O[U]===ne?(E[B]=C[U],B++):D.splice(B,1)}return S[b]=D.length,i.createSparseMatrix({values:E,index:D,ptr:S,size:[m,b],datatype:f===i._datatype&&g===o._datatype?v:void 0})}});var i2="matAlgo10xSids",o2=["typed","DenseMatrix"],g_=ve(i2,o2,t=>{var{typed:e,DenseMatrix:n}=t;return function(i,o,s,a){var l=i._values,u=i._index,c=i._ptr,f=i._size,h=i._datatype;if(!l)throw new Error("Cannot perform operation on Pattern Sparse Matrix and Scalar value");var d=f[0],x=f[1],p,g=s;typeof h=="string"&&(p=h,o=e.convert(o,p),g=e.find(s,[p,p]));for(var m=[],b=[],v=[],_=0;_<x;_++){for(var M=_+1,y=c[_],E=c[_+1],D=y;D<E;D++){var S=u[D];b[S]=l[D],v[S]=M}for(var w=0;w<d;w++)_===0&&(m[w]=[]),v[w]===M?m[w][_]=a?g(o,b[w]):g(b[w],o):m[w][_]=o}return new n({data:m,size:[d,x],datatype:p})}});function Or(t,e,n,r){if(!(this instanceof Or))throw new SyntaxError("Constructor must be called with the new operator");this.fn=t,this.count=e,this.min=n,this.max=r,this.message="Wrong number of arguments in function "+t+" ("+e+" provided, "+n+(r!=null?"-"+r:"")+" expected)",this.stack=new Error().stack}Or.prototype=new Error;Or.prototype.constructor=Error;Or.prototype.name="ArgumentsError";Or.prototype.isArgumentsError=!0;var s2="multiplyScalar",a2=["typed"],Tp=ve(s2,a2,t=>{var{typed:e}=t;return e("multiplyScalar",{"number, number":gp,"Complex, Complex":function(r,i){return r.mul(i)},"BigNumber, BigNumber":function(r,i){return r.times(i)},"bigint, bigint":function(r,i){return r*i},"Fraction, Fraction":function(r,i){return r.mul(i)},"number | Fraction | BigNumber | Complex, Unit":(n,r)=>r.multiply(n),"Unit, number | Fraction | BigNumber | Complex | Unit":(n,r)=>n.multiply(r)})});var x_="multiply",u2=["typed","matrix","addScalar","multiplyScalar","equalScalar","dot"],Rp=ve(x_,u2,t=>{var{typed:e,matrix:n,addScalar:r,multiplyScalar:i,equalScalar:o,dot:s}=t,a=f_({typed:e,equalScalar:o}),l=sf({typed:e});function u(M,y){switch(M.length){case 1:switch(y.length){case 1:if(M[0]!==y[0])throw new RangeError("Dimension mismatch in multiplication. Vectors must have the same length");break;case 2:if(M[0]!==y[0])throw new RangeError("Dimension mismatch in multiplication. Vector length ("+M[0]+") must match Matrix rows ("+y[0]+")");break;default:throw new Error("Can only multiply a 1 or 2 dimensional matrix (Matrix B has "+y.length+" dimensions)")}break;case 2:switch(y.length){case 1:if(M[1]!==y[0])throw new RangeError("Dimension mismatch in multiplication. Matrix columns ("+M[1]+") must match Vector length ("+y[0]+")");break;case 2:if(M[1]!==y[0])throw new RangeError("Dimension mismatch in multiplication. Matrix A columns ("+M[1]+") must match Matrix B rows ("+y[0]+")");break;default:throw new Error("Can only multiply a 1 or 2 dimensional matrix (Matrix B has "+y.length+" dimensions)")}break;default:throw new Error("Can only multiply a 1 or 2 dimensional matrix (Matrix A has "+M.length+" dimensions)")}}function c(M,y,E){if(E===0)throw new Error("Cannot multiply two empty vectors");return s(M,y)}function f(M,y){if(y.storage()!=="dense")throw new Error("Support for SparseMatrix not implemented");return h(M,y)}function h(M,y){var E=M._data,D=M._size,S=M._datatype||M.getDataType(),w=y._data,C=y._size,F=y._datatype||y.getDataType(),O=D[0],U=C[1],z,B=r,J=i;S&&F&&S===F&&typeof S=="string"&&S!=="mixed"&&(z=S,B=e.find(r,[z,z]),J=e.find(i,[z,z]));for(var H=[],ne=0;ne<U;ne++){for(var se=J(E[0],w[0][ne]),ge=1;ge<O;ge++)se=B(se,J(E[ge],w[ge][ne]));H[ne]=se}return M.createDenseMatrix({data:H,size:[U],datatype:S===M._datatype&&F===y._datatype?z:void 0})}var d=e("_multiplyMatrixVector",{"DenseMatrix, any":p,"SparseMatrix, any":b}),x=e("_multiplyMatrixMatrix",{"DenseMatrix, DenseMatrix":g,"DenseMatrix, SparseMatrix":m,"SparseMatrix, DenseMatrix":v,"SparseMatrix, SparseMatrix":_});function p(M,y){var E=M._data,D=M._size,S=M._datatype||M.getDataType(),w=y._data,C=y._datatype||y.getDataType(),F=D[0],O=D[1],U,z=r,B=i;S&&C&&S===C&&typeof S=="string"&&S!=="mixed"&&(U=S,z=e.find(r,[U,U]),B=e.find(i,[U,U]));for(var J=[],H=0;H<F;H++){for(var ne=E[H],se=B(ne[0],w[0]),ge=1;ge<O;ge++)se=z(se,B(ne[ge],w[ge]));J[H]=se}return M.createDenseMatrix({data:J,size:[F],datatype:S===M._datatype&&C===y._datatype?U:void 0})}function g(M,y){var E=M._data,D=M._size,S=M._datatype||M.getDataType(),w=y._data,C=y._size,F=y._datatype||y.getDataType(),O=D[0],U=D[1],z=C[1],B,J=r,H=i;S&&F&&S===F&&typeof S=="string"&&S!=="mixed"&&S!=="mixed"&&(B=S,J=e.find(r,[B,B]),H=e.find(i,[B,B]));for(var ne=[],se=0;se<O;se++){var ge=E[se];ne[se]=[];for(var Te=0;Te<z;Te++){for(var ze=H(ge[0],w[0][Te]),Ze=1;Ze<U;Ze++)ze=J(ze,H(ge[Ze],w[Ze][Te]));ne[se][Te]=ze}}return M.createDenseMatrix({data:ne,size:[O,z],datatype:S===M._datatype&&F===y._datatype?B:void 0})}function m(M,y){var E=M._data,D=M._size,S=M._datatype||M.getDataType(),w=y._values,C=y._index,F=y._ptr,O=y._size,U=y._datatype||y._data===void 0?y._datatype:y.getDataType();if(!w)throw new Error("Cannot multiply Dense Matrix times Pattern only Matrix");var z=D[0],B=O[1],J,H=r,ne=i,se=o,ge=0;S&&U&&S===U&&typeof S=="string"&&S!=="mixed"&&(J=S,H=e.find(r,[J,J]),ne=e.find(i,[J,J]),se=e.find(o,[J,J]),ge=e.convert(0,J));for(var Te=[],ze=[],Ze=[],ke=y.createSparseMatrix({values:Te,index:ze,ptr:Ze,size:[z,B],datatype:S===M._datatype&&U===y._datatype?J:void 0}),re=0;re<B;re++){Ze[re]=ze.length;var ae=F[re],Se=F[re+1];if(Se>ae)for(var De=0,xe=0;xe<z;xe++){for(var Xe=xe+1,ut=void 0,N=ae;N<Se;N++){var Je=C[N];De!==Xe?(ut=ne(E[xe][Je],w[N]),De=Xe):ut=H(ut,ne(E[xe][Je],w[N]))}De===Xe&&!se(ut,ge)&&(ze.push(xe),Te.push(ut))}}return Ze[B]=ze.length,ke}function b(M,y){var E=M._values,D=M._index,S=M._ptr,w=M._datatype||M._data===void 0?M._datatype:M.getDataType();if(!E)throw new Error("Cannot multiply Pattern only Matrix times Dense Matrix");var C=y._data,F=y._datatype||y.getDataType(),O=M._size[0],U=y._size[0],z=[],B=[],J=[],H,ne=r,se=i,ge=o,Te=0;w&&F&&w===F&&typeof w=="string"&&w!=="mixed"&&(H=w,ne=e.find(r,[H,H]),se=e.find(i,[H,H]),ge=e.find(o,[H,H]),Te=e.convert(0,H));var ze=[],Ze=[];J[0]=0;for(var ke=0;ke<U;ke++){var re=C[ke];if(!ge(re,Te))for(var ae=S[ke],Se=S[ke+1],De=ae;De<Se;De++){var xe=D[De];Ze[xe]?ze[xe]=ne(ze[xe],se(re,E[De])):(Ze[xe]=!0,B.push(xe),ze[xe]=se(re,E[De]))}}for(var Xe=B.length,ut=0;ut<Xe;ut++){var N=B[ut];z[ut]=ze[N]}return J[1]=B.length,M.createSparseMatrix({values:z,index:B,ptr:J,size:[O,1],datatype:w===M._datatype&&F===y._datatype?H:void 0})}function v(M,y){var E=M._values,D=M._index,S=M._ptr,w=M._datatype||M._data===void 0?M._datatype:M.getDataType();if(!E)throw new Error("Cannot multiply Pattern only Matrix times Dense Matrix");var C=y._data,F=y._datatype||y.getDataType(),O=M._size[0],U=y._size[0],z=y._size[1],B,J=r,H=i,ne=o,se=0;w&&F&&w===F&&typeof w=="string"&&w!=="mixed"&&(B=w,J=e.find(r,[B,B]),H=e.find(i,[B,B]),ne=e.find(o,[B,B]),se=e.convert(0,B));for(var ge=[],Te=[],ze=[],Ze=M.createSparseMatrix({values:ge,index:Te,ptr:ze,size:[O,z],datatype:w===M._datatype&&F===y._datatype?B:void 0}),ke=[],re=[],ae=0;ae<z;ae++){ze[ae]=Te.length;for(var Se=ae+1,De=0;De<U;De++){var xe=C[De][ae];if(!ne(xe,se))for(var Xe=S[De],ut=S[De+1],N=Xe;N<ut;N++){var Je=D[N];re[Je]!==Se?(re[Je]=Se,Te.push(Je),ke[Je]=H(xe,E[N])):ke[Je]=J(ke[Je],H(xe,E[N]))}}for(var Ne=ze[ae],Be=Te.length,Ae=Ne;Ae<Be;Ae++){var pt=Te[Ae];ge[Ae]=ke[pt]}}return ze[z]=Te.length,Ze}function _(M,y){var E=M._values,D=M._index,S=M._ptr,w=M._datatype||M._data===void 0?M._datatype:M.getDataType(),C=y._values,F=y._index,O=y._ptr,U=y._datatype||y._data===void 0?y._datatype:y.getDataType(),z=M._size[0],B=y._size[1],J=E&&C,H,ne=r,se=i;w&&U&&w===U&&typeof w=="string"&&w!=="mixed"&&(H=w,ne=e.find(r,[H,H]),se=e.find(i,[H,H]));for(var ge=J?[]:void 0,Te=[],ze=[],Ze=M.createSparseMatrix({values:ge,index:Te,ptr:ze,size:[z,B],datatype:w===M._datatype&&U===y._datatype?H:void 0}),ke=J?[]:void 0,re=[],ae,Se,De,xe,Xe,ut,N,Je,Ne=0;Ne<B;Ne++){ze[Ne]=Te.length;var Be=Ne+1;for(Xe=O[Ne],ut=O[Ne+1],xe=Xe;xe<ut;xe++)if(Je=F[xe],J)for(Se=S[Je],De=S[Je+1],ae=Se;ae<De;ae++)N=D[ae],re[N]!==Be?(re[N]=Be,Te.push(N),ke[N]=se(C[xe],E[ae])):ke[N]=ne(ke[N],se(C[xe],E[ae]));else for(Se=S[Je],De=S[Je+1],ae=Se;ae<De;ae++)N=D[ae],re[N]!==Be&&(re[N]=Be,Te.push(N));if(J)for(var Ae=ze[Ne],pt=Te.length,Fe=Ae;Fe<pt;Fe++){var $e=Te[Fe];ge[Fe]=ke[$e]}}return ze[B]=Te.length,Ze}return e(x_,i,{"Array, Array":e.referTo("Matrix, Matrix",M=>(y,E)=>{u(Pt(y),Pt(E));var D=M(n(y),n(E));return at(D)?D.valueOf():D}),"Matrix, Matrix":function(y,E){var D=y.size(),S=E.size();return u(D,S),D.length===1?S.length===1?c(y,E,D[0]):f(y,E):S.length===1?d(y,E):x(y,E)},"Matrix, Array":e.referTo("Matrix,Matrix",M=>(y,E)=>M(y,n(E))),"Array, Matrix":e.referToSelf(M=>(y,E)=>M(n(y,E.storage()),E)),"SparseMatrix, any":function(y,E){return a(y,E,i,!1)},"DenseMatrix, any":function(y,E){return l(y,E,i,!1)},"any, SparseMatrix":function(y,E){return a(E,y,i,!0)},"any, DenseMatrix":function(y,E){return l(E,y,i,!0)},"Array, any":function(y,E){return l(n(y),E,i,!1).valueOf()},"any, Array":function(y,E){return l(n(E),y,i,!0).valueOf()},"any, any":i,"any, any, ...any":e.referToSelf(M=>(y,E,D)=>{for(var S=M(y,E),w=0;w<D.length;w++)S=M(S,D[w]);return S})})});var v_="conj",l2=["typed"],Fp=ve(v_,l2,t=>{var{typed:e}=t;return e(v_,{"number | BigNumber | Fraction":n=>n,Complex:n=>n.conjugate(),Unit:e.referToSelf(n=>r=>new r.constructor(n(r.toNumeric()),r.formatUnits())),"Array | Matrix":e.referToSelf(n=>r=>sn(r,n))})});var __="concat",c2=["typed","matrix","isInteger"],Pp=ve(__,c2,t=>{var{typed:e,matrix:n,isInteger:r}=t;return e(__,{"...Array | Matrix | number | BigNumber":function(o){var s,a=o.length,l=-1,u,c=!1,f=[];for(s=0;s<a;s++){var h=o[s];if(at(h)&&(c=!0),ot(h)||st(h)){if(s!==a-1)throw new Error("Dimension must be specified as last argument");if(u=l,l=h.valueOf(),!r(l))throw new TypeError("Integer number expected for dimension");if(l<0||s>0&&l>u)throw new sr(l,u+1)}else{var d=ft(h).valueOf(),x=Pt(d);if(f[s]=d,u=l,l=x.length-1,s>0&&l!==u)throw new rt(u+1,l+1)}}if(f.length===0)throw new SyntaxError("At least one matrix expected");for(var p=f.shift();f.length;)p=ap(p,f.shift(),l);return c?n(p):p},"...string":function(o){return o.join("")}})});var y_="identity",f2=["typed","config","matrix","BigNumber","DenseMatrix","SparseMatrix"],Ip=ve(y_,f2,t=>{var{typed:e,config:n,matrix:r,BigNumber:i,DenseMatrix:o,SparseMatrix:s}=t;return e(y_,{"":function(){return n.matrix==="Matrix"?r([]):[]},string:function(c){return r(c)},"number | BigNumber":function(c){return l(c,c,n.matrix==="Matrix"?"dense":void 0)},"number | BigNumber, string":function(c,f){return l(c,c,f)},"number | BigNumber, number | BigNumber":function(c,f){return l(c,f,n.matrix==="Matrix"?"dense":void 0)},"number | BigNumber, number | BigNumber, string":function(c,f,h){return l(c,f,h)},Array:function(c){return a(c)},"Array, string":function(c,f){return a(c,f)},Matrix:function(c){return a(c.valueOf(),c.storage())},"Matrix, string":function(c,f){return a(c.valueOf(),f)}});function a(u,c){switch(u.length){case 0:return c?r(c):[];case 1:return l(u[0],u[0],c);case 2:return l(u[0],u[1],c);default:throw new Error("Vector containing two values expected")}}function l(u,c,f){var h=st(u)||st(c)?i:null;if(st(u)&&(u=u.toNumber()),st(c)&&(c=c.toNumber()),!ht(u)||u<1)throw new Error("Parameters in function identity must be positive integers");if(!ht(c)||c<1)throw new Error("Parameters in function identity must be positive integers");var d=h?new i(1):1,x=h?new h(0):0,p=[u,c];if(f){if(f==="sparse")return s.diagonal(p,d,0,x);if(f==="dense")return o.diagonal(p,d,0,x);throw new TypeError('Unknown matrix type "'.concat(f,'"'))}for(var g=Ma([],p,x),m=u<c?u:c,b=0;b<m;b++)g[b][b]=d;return g}});function M_(){throw new Error('No "bignumber" implementation available')}function S_(){throw new Error('No "fraction" implementation available')}function w_(){throw new Error('No "matrix" implementation available')}var b_="size",h2=["typed","config","?matrix"],Np=ve(b_,h2,t=>{var{typed:e,config:n,matrix:r}=t;return e(b_,{Matrix:function(o){return o.create(o.size(),"number")},Array:Pt,string:function(o){return n.matrix==="Array"?[o.length]:r([o.length],"dense","number")},"number | Complex | BigNumber | Unit | boolean | null":function(o){return n.matrix==="Array"?[]:r?r([],"dense","number"):w_()}})});var d2="numeric",p2=["number","?bignumber","?fraction"],Lp=ve(d2,p2,t=>{var{number:e,bignumber:n,fraction:r}=t,i={string:!0,number:!0,BigNumber:!0,Fraction:!0},o={number:s=>e(s),BigNumber:n?s=>n(s):M_,bigint:s=>BigInt(s),Fraction:r?s=>r(s):S_};return function(a){var l=arguments.length>1&&arguments[1]!==void 0?arguments[1]:"number",u=arguments.length>2?arguments[2]:void 0;if(u!==void 0)throw new SyntaxError("numeric() takes one or two arguments");var c=Fn(a);if(!(c in i))throw new TypeError("Cannot convert "+a+' of type "'+c+'"; valid input types are '+Object.keys(i).join(", "));if(!(l in o))throw new TypeError("Cannot convert "+a+' to type "'+l+'"; valid output types are '+Object.keys(o).join(", "));return l===c?a:o[l](a)}});var E_="divideScalar",m2=["typed","numeric"],Bp=ve(E_,m2,t=>{var{typed:e,numeric:n}=t;return e(E_,{"number, number":function(i,o){return i/o},"Complex, Complex":function(i,o){return i.div(o)},"BigNumber, BigNumber":function(i,o){return i.div(o)},"bigint, bigint":function(i,o){return i/o},"Fraction, Fraction":function(i,o){return i.div(o)},"Unit, number | Complex | Fraction | BigNumber | Unit":(r,i)=>r.divide(i),"number | Fraction | Complex | BigNumber, Unit":(r,i)=>i.divideInto(r)})});var D_="add",g2=["typed","matrix","addScalar","equalScalar","DenseMatrix","SparseMatrix","concat"],Up=ve(D_,g2,t=>{var{typed:e,matrix:n,addScalar:r,equalScalar:i,DenseMatrix:o,SparseMatrix:s,concat:a}=t,l=p_({typed:e}),u=m_({typed:e,equalScalar:i}),c=g_({typed:e,DenseMatrix:o}),f=d_({typed:e,matrix:n,concat:a});return e(D_,{"any, any":r,"any, any, ...any":e.referToSelf(h=>(d,x,p)=>{for(var g=h(d,x),m=0;m<p.length;m++)g=h(g,p[m]);return g})},f({elop:r,DS:l,SS:u,Ss:c}))});var A_="dot",x2=["typed","addScalar","multiplyScalar","conj","size"],Op=ve(A_,x2,t=>{var{typed:e,addScalar:n,multiplyScalar:r,conj:i,size:o}=t;return e(A_,{"Array | DenseMatrix, Array | DenseMatrix":a,"SparseMatrix, SparseMatrix":l});function s(c,f){var h=u(c),d=u(f),x,p;if(h.length===1)x=h[0];else if(h.length===2&&h[1]===1)x=h[0];else throw new RangeError("Expected a column vector, instead got a matrix of size ("+h.join(", ")+")");if(d.length===1)p=d[0];else if(d.length===2&&d[1]===1)p=d[0];else throw new RangeError("Expected a column vector, instead got a matrix of size ("+d.join(", ")+")");if(x!==p)throw new RangeError("Vectors must have equal length ("+x+" != "+p+")");if(x===0)throw new RangeError("Cannot calculate the dot product of empty vectors");return x}function a(c,f){var h=s(c,f),d=at(c)?c._data:c,x=at(c)?c._datatype||c.getDataType():void 0,p=at(f)?f._data:f,g=at(f)?f._datatype||f.getDataType():void 0,m=u(c).length===2,b=u(f).length===2,v=n,_=r;if(x&&g&&x===g&&typeof x=="string"&&x!=="mixed"){var M=x;v=e.find(n,[M,M]),_=e.find(r,[M,M])}if(!m&&!b){for(var y=_(i(d[0]),p[0]),E=1;E<h;E++)y=v(y,_(i(d[E]),p[E]));return y}if(!m&&b){for(var D=_(i(d[0]),p[0][0]),S=1;S<h;S++)D=v(D,_(i(d[S]),p[S][0]));return D}if(m&&!b){for(var w=_(i(d[0][0]),p[0]),C=1;C<h;C++)w=v(w,_(i(d[C][0]),p[C]));return w}if(m&&b){for(var F=_(i(d[0][0]),p[0][0]),O=1;O<h;O++)F=v(F,_(i(d[O][0]),p[O][0]));return F}}function l(c,f){s(c,f);for(var h=c._index,d=c._values,x=f._index,p=f._values,g=0,m=n,b=r,v=0,_=0;v<h.length&&_<x.length;){var M=h[v],y=x[_];if(M<y){v++;continue}if(M>y){_++;continue}M===y&&(g=m(g,b(d[v],p[_])),v++,_++)}return g}function u(c){return at(c)?c.size():o(c)}});var C_="det",v2=["typed","matrix","subtractScalar","multiply","divideScalar","isZero","unaryMinus"],zp=ve(C_,v2,t=>{var{typed:e,matrix:n,subtractScalar:r,multiply:i,divideScalar:o,isZero:s,unaryMinus:a}=t;return e(C_,{any:function(c){return ft(c)},"Array | Matrix":function(c){var f;switch(at(c)?f=c.size():Array.isArray(c)?(c=n(c),f=c.size()):f=[],f.length){case 0:return ft(c);case 1:if(f[0]===1)return ft(c.valueOf()[0]);if(f[0]===0)return 1;throw new RangeError("Matrix must be square (size: "+St(f)+")");case 2:{var h=f[0],d=f[1];if(h===d)return l(c.clone().valueOf(),h,d);if(d===0)return 1;throw new RangeError("Matrix must be square (size: "+St(f)+")")}default:throw new RangeError("Matrix must be two dimensional (size: "+St(f)+")")}}});function l(u,c,f){if(c===1)return ft(u[0][0]);if(c===2)return r(i(u[0][0],u[1][1]),i(u[1][0],u[0][1]));for(var h=!1,d=new Array(c).fill(0).map((E,D)=>D),x=0;x<c;x++){var p=d[x];if(s(u[p][x])){var g=void 0;for(g=x+1;g<c;g++)if(!s(u[d[g]][x])){p=d[g],d[g]=d[x],d[x]=p,h=!h;break}if(g===c)return u[p][x]}for(var m=u[p][x],b=x===0?1:u[d[x-1]][x-1],v=x+1;v<c;v++)for(var _=d[v],M=x+1;M<c;M++)u[_][M]=o(r(i(u[_][M],m),i(u[_][x],u[p][M])),b)}var y=u[d[c-1]][c-1];return h?a(y):y}});var T_="inv",_2=["typed","matrix","divideScalar","addScalar","multiply","unaryMinus","det","identity","abs"],kp=ve(T_,_2,t=>{var{typed:e,matrix:n,divideScalar:r,addScalar:i,multiply:o,unaryMinus:s,det:a,identity:l,abs:u}=t;return e(T_,{"Array | Matrix":function(h){var d=at(h)?h.size():Pt(h);switch(d.length){case 1:if(d[0]===1)return at(h)?n([r(1,h.valueOf()[0])]):[r(1,h[0])];throw new RangeError("Matrix must be square (size: "+St(d)+")");case 2:{var x=d[0],p=d[1];if(x===p)return at(h)?n(c(h.valueOf(),x,p),h.storage()):c(h,x,p);throw new RangeError("Matrix must be square (size: "+St(d)+")")}default:throw new RangeError("Matrix must be two dimensional (size: "+St(d)+")")}},any:function(h){return r(1,h)}});function c(f,h,d){var x,p,g,m,b;if(h===1){if(m=f[0][0],m===0)throw Error("Cannot calculate inverse, determinant is zero");return[[r(1,m)]]}else if(h===2){var v=a(f);if(v===0)throw Error("Cannot calculate inverse, determinant is zero");return[[r(f[1][1],v),r(s(f[0][1]),v)],[r(s(f[1][0]),v),r(f[0][0],v)]]}else{var _=f.concat();for(x=0;x<h;x++)_[x]=_[x].concat();for(var M=l(h).valueOf(),y=0;y<d;y++){var E=u(_[y][y]),D=y;for(x=y+1;x<h;)u(_[x][y])>E&&(E=u(_[x][y]),D=x),x++;if(E===0)throw Error("Cannot calculate inverse, determinant is zero");x=D,x!==y&&(b=_[y],_[y]=_[x],_[x]=b,b=M[y],M[y]=M[x],M[x]=b);var S=_[y],w=M[y];for(x=0;x<h;x++){var C=_[x],F=M[x];if(x!==y){if(C[y]!==0){for(g=r(s(C[y]),S[y]),p=y;p<d;p++)C[p]=i(C[p],o(g,S[p]));for(p=0;p<d;p++)F[p]=i(F[p],o(g,w[p]))}}else{for(g=S[y],p=y;p<d;p++)C[p]=r(C[p],g);for(p=0;p<d;p++)F[p]=r(F[p],g)}}}return M}}});var R_="expm",y2=["typed","abs","add","identity","inv","multiply"],Vp=ve(R_,y2,t=>{var{typed:e,abs:n,add:r,identity:i,inv:o,multiply:s}=t;return e(R_,{Matrix:function(f){var h=f.size();if(h.length!==2||h[0]!==h[1])throw new RangeError("Matrix must be square (size: "+St(h)+")");for(var d=h[0],x=1e-15,p=a(f),g=l(p,x),m=g.q,b=g.j,v=s(f,Math.pow(2,-b)),_=i(d),M=i(d),y=1,E=v,D=-1,S=1;S<=m;S++)S>1&&(E=s(E,v),D=-D),y=y*(m-S+1)/((2*m-S+1)*S),_=r(_,s(y,E)),M=r(M,s(y*D,E));for(var w=s(o(M),_),C=0;C<b;C++)w=s(w,w);return Jo(f)?f.createSparseMatrix(w):w}});function a(c){for(var f=c.size()[0],h=0,d=0;d<f;d++){for(var x=0,p=0;p<f;p++)x+=n(c.get([d,p]));h=Math.max(x,h)}return h}function l(c,f){for(var h=30,d=0;d<h;d++)for(var x=0;x<=d;x++){var p=d-x;if(u(c,x,p)<f)return{q:x,j:p}}throw new Error("Could not find acceptable parameters to compute the matrix exponential (try increasing maxSearchSize in expm.js)")}function u(c,f,h){for(var d=1,x=2;x<=f;x++)d*=x;for(var p=d,g=f+1;g<=2*f;g++)p*=g;var m=p*(2*f+1);return 8*Math.pow(c/Math.pow(2,h),2*f)*d*d/(p*m)}});var os={createBigNumberClass:Jd};var F_={createComplexClass:jd};var ss={createMatrixClass:np};var mi={MatrixDependencies:ss,createDenseMatrixClass:fp};var af={createFractionClass:tp};var qe={BigNumberDependencies:os,ComplexDependencies:F_,DenseMatrixDependencies:mi,FractionDependencies:af,createTyped:Gd};var uf={typedDependencies:qe,createAbs:Dp};var gi={typedDependencies:qe,createEqualScalar:_p};var as={MatrixDependencies:ss,equalScalarDependencies:gi,typedDependencies:qe,createSparseMatrixClass:yp};var xi={typedDependencies:qe,createAddScalar:Ap};var P_={typedDependencies:qe,createIsInteger:hp};var Mn={DenseMatrixDependencies:mi,MatrixDependencies:ss,SparseMatrixDependencies:as,typedDependencies:qe,createMatrix:bp};var I_={isIntegerDependencies:P_,matrixDependencies:Mn,typedDependencies:qe,createConcat:Pp};var N_={DenseMatrixDependencies:mi,SparseMatrixDependencies:as,addScalarDependencies:xi,concatDependencies:I_,equalScalarDependencies:gi,matrixDependencies:Mn,typedDependencies:qe,createAdd:Up};var L_={BigNumberDependencies:os,typedDependencies:qe,createBignumber:Sp};var B_={FractionDependencies:af,typedDependencies:qe,createFraction:wp};var U_={typedDependencies:qe,createNumber:Mp};var O_={bignumberDependencies:L_,fractionDependencies:B_,numberDependencies:U_,createNumeric:Lp};var lf={numericDependencies:O_,typedDependencies:qe,createDivideScalar:Bp};var cf={typedDependencies:qe,createMultiplyScalar:Tp};var ff={BigNumberDependencies:os,DenseMatrixDependencies:mi,SparseMatrixDependencies:as,matrixDependencies:Mn,typedDependencies:qe,createIdentity:Ip};var z_={equalScalarDependencies:gi,typedDependencies:qe,createIsZero:vp};var k_={typedDependencies:qe,createConj:Fp};var V_={matrixDependencies:Mn,typedDependencies:qe,createSize:Np};var H_={addScalarDependencies:xi,conjDependencies:k_,multiplyScalarDependencies:cf,sizeDependencies:V_,typedDependencies:qe,createDot:Op};var zr={addScalarDependencies:xi,dotDependencies:H_,equalScalarDependencies:gi,matrixDependencies:Mn,multiplyScalarDependencies:cf,typedDependencies:qe,createMultiply:Rp};var G_={typedDependencies:qe,createSubtractScalar:Cp};var hf={typedDependencies:qe,createUnaryMinus:Ep};var W_={divideScalarDependencies:lf,isZeroDependencies:z_,matrixDependencies:Mn,multiplyDependencies:zr,subtractScalarDependencies:G_,typedDependencies:qe,unaryMinusDependencies:hf,createDet:zp};var q_={absDependencies:uf,addScalarDependencies:xi,detDependencies:W_,divideScalarDependencies:lf,identityDependencies:ff,matrixDependencies:Mn,multiplyDependencies:zr,typedDependencies:qe,unaryMinusDependencies:hf,createInv:kp};var Hp={absDependencies:uf,addDependencies:N_,identityDependencies:ff,invDependencies:q_,multiplyDependencies:zr,typedDependencies:qe,createExpm:Vp};var J_=Pa(Hc(),1);var Y_=Pa(X_(),1);function Z_(t){var e=new Y_.default;return t.on=e.on.bind(e),t.off=e.off.bind(e),t.once=e.once.bind(e),t.emit=e.emit.bind(e),t}function $_(t,e,n,r){function i(m,b){var v=arguments.length;if(v!==1&&v!==2)throw new Or("import",v,1,2);b||(b={});function _(D,S,w){if(Array.isArray(S))S.forEach(O=>_(D,O));else if(rr(S)||f(S))for(var C in S)dn(S,C)&&_(D,S[C],C);else if(eo(S)||w!==void 0){var F=eo(S)?p(S)?S.fn+".transform":S.fn:w;if(dn(D,F)&&D[F]!==S&&!b.silent)throw new Error('Cannot import "'+F+'" twice');D[F]=S}else if(!b.silent)throw new TypeError("Factory, Object, or Array expected")}var M={};_(M,m);for(var y in M)if(dn(M,y)){var E=M[y];if(eo(E))u(E,b);else if(c(E))o(y,E,b);else if(!b.silent)throw new TypeError("Factory, Object, or Array expected")}}function o(m,b,v){var _;if(v.wrap&&typeof b=="function"&&(b=l(b)),h(b)&&(b=t(m,{[b.signature]:b})),t.isTypedFunction(n[m])&&t.isTypedFunction(b)){v.override?b=t(m,b.signatures):b=t(n[m],b),n[m]=b,delete r[m],s(m,b),n.emit("import",m,function(){return b});return}var M=n[m]!==void 0,y=(_=n.Unit)===null||_===void 0?void 0:_.isValuelessUnit(m);if(!M&&!y||v.override){n[m]=b,delete r[m],s(m,b),n.emit("import",m,function(){return b});return}if(!v.silent)throw new Error('Cannot import "'+m+'": already exists')}function s(m,b){b&&typeof b.transform=="function"?(n.expression.transform[m]=b.transform,d(m)&&(n.expression.mathWithTransform[m]=b.transform)):(delete n.expression.transform[m],d(m)&&(n.expression.mathWithTransform[m]=b))}function a(m){delete n.expression.transform[m],d(m)?n.expression.mathWithTransform[m]=n[m]:delete n.expression.mathWithTransform[m]}function l(m){var b=function(){for(var _=[],M=0,y=arguments.length;M<y;M++){var E=arguments[M];_[M]=E&&E.valueOf()}return m.apply(n,_)};return m.transform&&(b.transform=m.transform),b}function u(m,b){var v,_,M=arguments.length>2&&arguments[2]!==void 0?arguments[2]:m.fn;if(M.includes("."))throw new Error("Factory name should not contain a nested path. Name: "+JSON.stringify(M));var y=p(m)?n.expression.transform:n,E=M in n.expression.transform,D=dn(y,M)?y[M]:void 0,S=function(){var U={};m.dependencies.map(zd).forEach(B=>{if(B.includes("."))throw new Error("Factory dependency should not contain a nested path. Name: "+JSON.stringify(B));B==="math"?U.math=n:B==="mathWithTransform"?U.mathWithTransform=n.expression.mathWithTransform:B==="classes"?U.classes=n:U[B]=n[B]});var z=m(U);if(z&&typeof z.transform=="function")throw new Error('Transforms cannot be attached to factory functions. Please create a separate function for it with export const path = "expression.transform"');if(D===void 0||b.override)return z;if(t.isTypedFunction(D)&&t.isTypedFunction(z))return t(D,z);if(b.silent)return D;throw new Error('Cannot import "'+M+'": already exists')},w=(v=(_=m.meta)===null||_===void 0?void 0:_.formerly)!==null&&v!==void 0?v:"",C=p(m)||x(m),F=n.expression.mathWithTransform;!m.meta||m.meta.lazy!==!1?(ji(y,M,S),w&&ji(y,w,S),D&&E?(a(M),w&&a(w)):C&&(ji(F,M,()=>y[M]),w&&ji(F,w,()=>y[M]))):(y[M]=S(),w&&(y[w]=y[M]),D&&E?(a(M),w&&a(w)):C&&(ji(F,M,()=>y[M]),w&&ji(F,w,()=>y[M]))),r[M]=m,n.emit("import",M,S)}function c(m){return typeof m=="function"||typeof m=="number"||typeof m=="string"||typeof m=="boolean"||m===null||ui(m)||Ki(m)||st(m)||Qi(m)||at(m)||Array.isArray(m)}function f(m){return typeof m=="object"&&m[Symbol.toStringTag]==="Module"}function h(m){return typeof m=="function"&&typeof m.signature=="string"}function d(m){return!dn(g,m)}function x(m){return!m.fn.includes(".")&&!dn(g,m.fn)&&(!m.meta||!m.meta.isClass)}function p(m){return m!==void 0&&m.meta!==void 0&&m.meta.isTransformFunction===!0||!1}var g={expression:!0,type:!0,docs:!0,error:!0,json:!0,chain:!0};return i}function df(t,e){var n=$o({},hc,e);if(typeof Object.create!="function")throw new Error("ES5 not supported by this JavaScript engine. Please load the es5-shim and es5-sham library for compatibility.");var r=Z_({isNumber:ot,isComplex:Ki,isBigNumber:st,isBigInt:pc,isFraction:Qi,isUnit:ui,isString:Kt,isArray:bt,isMatrix:at,isCollection:gr,isDenseMatrix:mc,isSparseMatrix:Jo,isRange:gc,isIndex:li,isBoolean:xc,isResultSet:vc,isHelp:_c,isFunction:yc,isDate:Mc,isRegExp:Sc,isObject:rr,isMap:ai,isPartitionedMap:ov,isObjectWrappingMap:sv,isNull:wc,isUndefined:bc,isAccessorNode:Ec,isArrayNode:Dc,isAssignmentNode:Ac,isBlockNode:Cc,isConditionalNode:Tc,isConstantNode:Rc,isFunctionAssignmentNode:Fc,isFunctionNode:Pc,isIndexNode:Ic,isNode:Nc,isObjectNode:Lc,isOperatorNode:Bc,isParenthesisNode:Uc,isRangeNode:Oc,isRelationalNode:zc,isSymbolNode:kc,isChain:Vc});r.config=mv(n,r.emit),r.expression={transform:{},mathWithTransform:{config:r.config}};var i=[],o=[];function s(c){if(eo(c))return c(r);var f=c[Object.keys(c)[0]];if(eo(f))return f(r);if(!cv(c))throw console.warn("Factory object with properties `type`, `name`, and `factory` expected",c),new Error("Factory object with properties `type`, `name`, and `factory` expected");var h=i.indexOf(c),d;return h===-1?(c.math===!0?d=c.factory(r.type,n,s,r.typed,r):d=c.factory(r.type,n,s,r.typed),i.push(c),o.push(d)):d=o[h],d}var a={};function l(){for(var c=arguments.length,f=new Array(c),h=0;h<c;h++)f[h]=arguments[h];return r.typed.apply(r.typed,f)}l.isTypedFunction=J_.default.isTypedFunction;var u=$_(l,s,r,a);return r.import=u,r.on("config",()=>{Object.values(a).forEach(c=>{c&&c.meta&&c.meta.recreateOnConfigChange&&u(c,{override:!0})})}),r.create=df.bind(null,t),r.factory=ve,r.import(Object.values(uv(t))),r.ArgumentsError=Or,r.DimensionError=rt,r.IndexError=sr,r}var{expm:S2,multiply:w2}=df({...Hp,...zr}),pf=Object.freeze({mode:"harmonic",m:1,k:4,zeta:.12,force:.8,ratio:1,phase:0,x0:1,v0:0,cycles:8}),Q_=Object.freeze({release:{label:"Free release",mode:"harmonic",x0:1,v0:0},kick:{label:"Velocity kick",mode:"harmonic",x0:0,v0:2},damped:{label:"Weak damping",mode:"damped",zeta:.12},critical:{label:"Critical return",mode:"damped",zeta:1},overdamped:{label:"Overdamped return",mode:"damped",zeta:1.6},resonance:{label:"Driven resonance",mode:"driven",zeta:.12,x0:0,force:.8,ratio:1},undamped:{label:"Undamped resonance",mode:"driven",zeta:0,x0:0,force:.8,ratio:1},beats:{label:"Driven transient",mode:"driven",zeta:.03,force:.4,ratio:.85}});function vi(t={}){let e={...pf,...t};if(!["harmonic","damped","driven"].includes(e.mode))throw new Error("Unknown oscillator mode");let n={m:[.25,5],k:[1,40],zeta:[0,2],force:[0,4],ratio:[.1,3],phase:[-180,180],x0:[-1.5,1.5],v0:[-3,3],cycles:[2,12]};for(let[r,[i,o]]of Object.entries(n))if(!Number.isFinite(e[r])||e[r]<i||e[r]>o)throw new Error(`Invalid ${r}`);return e}function us(t){let e=vi(t),n=Math.sqrt(e.k/e.m),r=2*Math.PI/n,i=e.mode==="harmonic"?0:e.zeta;return{omega0:n,period:r,f0:1/r,zeta:i,c:2*i*Math.sqrt(e.m*e.k),omega:e.ratio*n,force:e.mode==="driven"?e.force:0,duration:e.cycles*r}}function j_(t){let e=us(t);return e.zeta===0?"Undamped":e.zeta<1?"Underdamped":e.zeta===1?"Critically damped":"Overdamped"}function ey(t={},e){let n=vi(t),r=us(n),i=(e??n.ratio)*r.omega0,o=Math.hypot(n.k-n.m*i*i,r.c*i);return o<1e-12*n.k&&r.force>0?1/0:r.force===0?0:r.force/o}function b2(t){let e=vi(t),n=us(e),r=[[0,1,0,0],[-e.k/e.m,-n.c/e.m,n.force/e.m,0],[0,0,0,-n.omega],[0,0,n.omega,0]],i=Array.from({length:22},()=>Array(22).fill(0));for(let o=0;o<4;o++)for(let s=0;s<4;s++)i[o][s]=r[o][s];for(let o=0;o<4;o++)for(let s=0;s<4;s++)for(let a=0;a<4;a++)i[4+4*o+s][4+4*a+s]+=r[o][a],i[4+4*o+s][4+4*o+a]+=r[s][a];return i[20][9]=n.c,i[21][10]=n.force,i}function E2(t){let e=vi(t),n=e.phase*Math.PI/180,r=[e.x0,e.v0,Math.cos(n),Math.sin(n)];return[...r,...r.flatMap(i=>r.map(o=>i*o)),0,0]}function K_(t,e,n,r){let[i,o,s]=n,a=.5*t.m*o*o,l=.5*t.k*i*i,u=a+l,c=n[20],f=n[21],h=e.force*s;return{t:r,x:i,v:o,a:(h-e.c*o-t.k*i)/t.m,K:a,U:l,E:u,Q:c,W:f,F:h,balance:u+c-f-(.5*t.m*t.v0**2+.5*t.k*t.x0**2)}}function ty(t,e=1200){let n=vi(t),r=us(n);if(!Number.isInteger(e)||e<20||e>4e3)throw new Error("Invalid sample count");let i=r.duration/e,o=S2(b2(n).map(l=>l.map(u=>u*i))).toArray(),s=E2(n),a=[K_(n,r,s,0)];for(let l=1;l<=e;l++)s=w2(o,s),a.push(K_(n,r,s,l*i));return a}function ny(t,e){return"# "+JSON.stringify(vi(t))+`
time_s,x_m,v_m_s,a_m_s2,kinetic_J,potential_J,mechanical_J,dissipated_J,drive_work_J,drive_force_N,balance_error_J
`+e.map(n=>[n.t,n.x,n.v,n.a,n.K,n.U,n.E,n.Q,n.W,n.F,n.balance].map(r=>r.toPrecision(15)).join(",")).join(`
`)+`
`}var Ve=t=>document.getElementById(t),ry={x:"#16887c",v:"#d45c4d",K:"#16887c",U:"#b7831e",E:"#253b3e",Q:"#d45c4d",W:"#805c9c"},sy=[["m","Mass m (kg)",.25,5,.05],["k","Stiffness k (N/m)",1,40,.5],["zeta","Damping ratio \u03B6",0,2,.01],["x0","Initial x (m)",-1.5,1.5,.05],["v0","Initial v (m/s)",-3,3,.05],["force","Drive F\u2080 (N)",0,4,.05],["ratio","Drive \u03C9d / \u03C9\u2080",.1,3,.01],["phase","Drive phase (\xB0)",-180,180,5],["cycles","Natural periods",2,12,1]],Gt={...pf},ar,an=[],Sn=0,Yp=!1,ay=1,kr=0,uy=[],Ea,Xp;for(let[t,e,n,r,i]of sy){let o=document.createElement("div");o.className="field",o.innerHTML=`<div class="field-head"><label for="${t}-number">${e}</label><input id="${t}-number" type="number" min="${n}" max="${r}" step="${i}"></div><input id="${t}" type="range" min="${n}" max="${r}" step="${i}" aria-label="${e}">`,Ve("fields").append(o);for(let s of[t,t+"-number"])Ve(s).addEventListener("input",()=>{let a=Ve(s),l=Number(a.value);if(a.value.trim()===""||!Number.isFinite(l)||l<n||l>r){a.setAttribute("aria-invalid","true"),Ve("error").hidden=!1,Ve("error").textContent=`${e}: enter a value from ${n} to ${r}.`;return}a.removeAttribute("aria-invalid"),Gt[t]=l,Ve(t).value=l,Ve(t+"-number").value=l,Ve("preset").value="custom",clearTimeout(Xp),Xp=setTimeout(mf,70)})}function D2(){nv({icons:{Play:Pd,Pause:Fd,RotateCcw:Id,StepForward:Ld,Scan:Nd,Download:Rd}})}function ro(t){Yp=t;let e=t?"Pause":"Play";Ve("play").innerHTML=`<i data-lucide="${e.toLowerCase()}"></i>`,Ve("play").title=e,Ve("play").setAttribute("aria-label",e),D2()}function A2(){for(let[t]of sy)for(let e of[t,t+"-number"])Ve(e).value=Gt[t],Ve(e).disabled=t==="zeta"?Gt.mode==="harmonic":["force","ratio","phase"].includes(t)?Gt.mode!=="driven":!1,Ve(e).removeAttribute("aria-invalid");document.querySelectorAll("[data-mode]").forEach(t=>t.setAttribute("aria-pressed",String(t.dataset.mode===Gt.mode)))}document.querySelectorAll("[data-mode]").forEach(t=>t.addEventListener("click",()=>{Gt.mode=t.dataset.mode,Ve("preset").value="custom",mf()}));Ve("preset").addEventListener("change",()=>{let{label:t,...e}=Q_[Ve("preset").value]??{};Gt={...pf,...e},mf()});Ve("play").addEventListener("click",()=>{Sn===an.length-1&&(Sn=0,kr=0),ro(!Yp),io()});Ve("reset").addEventListener("click",()=>{ro(!1),Sn=0,kr=0,io()});Ve("step").addEventListener("click",()=>{ro(!1),Sn=Math.min(Sn+5,an.length-1),kr=an[Sn].t,io()});Ve("timeline").addEventListener("input",()=>{ro(!1),Sn=Number(Ve("timeline").value),kr=an[Sn].t,io()});Ve("speed").addEventListener("change",()=>{ay=Number(Ve("speed").value)});Ve("camera").addEventListener("click",()=>Ea?.reset());Ve("download").addEventListener("click",()=>{let t=URL.createObjectURL(new Blob([ny(Gt,an)],{type:"text/csv"})),e=document.createElement("a");e.href=t,e.download="oscillation.csv",e.click(),setTimeout(()=>URL.revokeObjectURL(t),1e3)});var In=(t,e=3)=>Math.abs(t)<1e-10?"0":Math.abs(t)>=1e4||Math.abs(t)<.001?t.toExponential(2):t.toFixed(e);function mf(){try{clearTimeout(Xp),Gt=vi(Gt),ar=us(Gt),an=ty(Gt),Sn=0,kr=0,ro(!1),A2(),Ve("error").hidden=!0,Ve("omega0").textContent=In(ar.omega0)+" rad/s",Ve("period").textContent=In(ar.period)+" s",Ve("frequency").textContent=In(ar.f0)+" Hz",Ve("damping").textContent=In(ar.c)+" N s/m",Ve("classification").textContent=j_(Gt)+(Gt.mode==="driven"?" \xB7 Driven":Gt.mode==="harmonic"?" \xB7 Free":" \xB7 Free decay");let t=Math.max(.25,...an.map(n=>Math.abs(n.x)));Ea?.configure(2.4/t),Ve("scale").textContent="Range \xB1"+In(t,2)+" m",Ve("force-label").hidden=Gt.mode!=="driven",Ve("response").hidden=Gt.mode!=="driven";let e=ey(Gt);Ve("response").textContent=e===1/0?"Undamped resonance: no bounded steady state.":(ar.zeta===0?"Particular-solution amplitude: ":"Steady-state amplitude: ")+In(e)+" m",uy=[qp("history","t",["x"]),qp("phase-plot","x",["v"]),qp("energy-plot","t",["K","U","E","Q","W"])],Ve("timeline").max=an.length-1,io()}catch(t){Ve("error").textContent=t.message,Ve("error").hidden=!1,ro(!1)}}function iy(t){let[e,n]=Nl(t),r=Math.max((n-e)*.09,.02);return[e-r,n+r]}function qp(t,e,n){let r=Ve(t),i=r.getContext("2d"),o={canvas:r,ctx:i,xKey:e,keys:n};return o.domainX=e==="t"?[0,ar.duration]:iy(an.map(s=>s[e])),o.domainY=iy(an.flatMap(s=>n.map(a=>s[a]))),o}function C2(t){let{canvas:e,ctx:n,xKey:r,keys:i}=t,o=e.clientWidth,s=e.clientHeight,a=Math.min(devicePixelRatio||1,2);if(o<1||!n)return;e.width=Math.round(o*a),e.height=Math.round(s*a),n.scale(a,a),n.clearRect(0,0,o,s);let l=Zo().domain(t.domainX).range([43,o-9]),u=Zo().domain(t.domainY).range([s-29,8]);n.font="10px system-ui",n.textBaseline="middle",n.strokeStyle="#e3ebe8",n.fillStyle="#748780";for(let f of u.ticks(4))n.beginPath(),n.moveTo(43,u(f)),n.lineTo(o-9,u(f)),n.stroke(),n.textAlign="right",n.fillText($i(".2~g")(f),37,u(f));for(let f of l.ticks(Math.max(3,Math.floor(o/75))))n.textAlign="center",n.fillText($i(".2~g")(f),l(f),s-12);n.save(),n.beginPath(),n.rect(43,8,Math.max(0,o-52),s-37),n.clip(),t.domainY[0]<0&&t.domainY[1]>0&&(n.strokeStyle="#bccdc6",n.beginPath(),n.moveTo(43,u(0)),n.lineTo(o-9,u(0)),n.stroke());for(let f of i)n.strokeStyle=ry[f],n.lineWidth=f==="E"?1.9:1.4,n.beginPath(),Dd().x(h=>l(h[r])).y(h=>u(h[f])).context(n)(an),n.stroke();let c=an[Sn];r==="t"&&(n.strokeStyle="#899f97",n.setLineDash([3,3]),n.beginPath(),n.moveTo(l(c.t),8),n.lineTo(l(c.t),s-29),n.stroke(),n.setLineDash([]));for(let f of i)n.fillStyle=ry[f],n.beginPath(),n.arc(l(c[r]),u(c[f]),3,0,Math.PI*2),n.fill();n.restore()}function io(){if(!an.length)return;let t=an[Sn];Ve("time").textContent=In(t.t,2)+" / "+In(ar.duration,2)+" s",Ve("timeline").value=Sn,Ve("timeline").setAttribute("aria-valuetext",In(t.t,2)+" seconds"),Ve("position").textContent=In(t.x)+" m",Ve("velocity").textContent=In(t.v)+" m/s",Ve("acceleration").textContent=In(t.a)+" m/s\xB2",Ve("energy").textContent=In(t.E)+" J",Ve("balance").textContent="Balance error "+t.balance.toExponential(1)+" J";for(let e of uy)C2(e);Ea?.update(t)}function T2(){let t=Ve("scene"),e=new Tl({antialias:!0,alpha:!1,preserveDrawingBuffer:!0});e.setPixelRatio(Math.min(devicePixelRatio||1,2)),e.setClearColor("#edf5f2"),t.prepend(e.domElement),e.domElement.setAttribute("aria-label","Animated spring and mass, with equilibrium marker and applied force"),e.domElement.setAttribute("role","img");let n=new Rs,r=new tn(34,1,.1,100);r.position.set(1.5,4.5,13);let i=new Pl(r,e.domElement);i.target.set(-1,0,0),i.enablePan=!1,i.minDistance=10,i.maxDistance=22,i.maxPolarAngle=Math.PI*.49,i.enableDamping=!0,i.update(),i.saveState(),n.add(new ks("#ffffff","#769d87",3));let o=new Hs("#ffffff",3);o.position.set(-3,6,4),n.add(o);let s=_=>new Bs({color:_,roughness:.45}),a=new Lt(new Ri(20,10),s("#dbeae3"));a.rotation.x=-Math.PI/2,a.position.y=-.5,n.add(a);let l=new Lt(new Qn(10.5,.04,.12),s("#8dac9f"));l.position.set(-.8,-.42,0),n.add(l);let u=new Lt(new Qn(.18,1.8,1.3),s("#80988f"));u.position.set(-5.2,.35,0),n.add(u);let c=new Lt(new Qn(.8,.8,.8),s("#d66b58"));n.add(c);let f=s("#278b7c"),h=new Lt(new cn,f);n.add(h);let d=new Fo(new cn().setFromPoints([new k(0,-.42,.5),new k(0,.9,.5)]),new Us({color:"#6c9385",dashSize:.08,gapSize:.06}));d.computeLineDistances(),n.add(d);let x=new Gs(new k(1,0,0),new k(0,1.15,0),1,"#b7831e",.18,.12);n.add(x);let p=new Er;for(let _=-4;_<=3;_++){let M=new Lt(new Qn(.015,.025,.5),s("#9bb7aa"));M.position.set(_,-.47,.5),p.add(M)}n.add(p);let g=1,m=NaN,b=()=>{let _=t.clientWidth,M=t.clientHeight;e.setSize(_,M,!1),r.aspect=_/M,r.updateProjectionMatrix()};new ResizeObserver(b).observe(t),b();function v(_){let M=_.x*g;if(c.position.x=M,!Number.isFinite(m)||Math.abs(M-m)>1e-7){let y=[];for(let D=0;D<=192;D++){let S=D/192,w=S*12*2*Math.PI;y.push(new k(-5.1+(M-.4+5.1)*S,.22*Math.cos(w),.22*Math.sin(w)))}let E=h.geometry;h.geometry=new Ls(new Po(y),192,.035,6,!1),E.dispose(),m=M}x.visible=Gt.mode==="driven"&&Math.abs(_.F)>.005,x.position.set(M,1.15,0),x.setDirection(new k(Math.sign(_.F)||1,0,0)),x.setLength(.25+Math.min(Math.abs(_.F),4)*.35,.18,.12)}return{update:v,configure(_){g=_,m=NaN},reset(){i.reset()},render(){i.update(),e.render(n,r)}}}try{Ea=T2()}catch{Ve("fallback").hidden=!1,Ve("camera").disabled=!0}new ResizeObserver(()=>io()).observe(Ve("history"));var oy=performance.now();function ly(t){let e=Math.min((t-oy)/1e3,.1);if(oy=t,Yp){kr=Math.min(kr+e*ay,ar.duration);let n=Math.min(an.length-1,Math.round(kr/ar.duration*(an.length-1)));n!==Sn&&(Sn=n,io()),kr>=ar.duration&&ro(!1)}Ea?.render(),requestAnimationFrame(ly)}mf();requestAnimationFrame(ly);})();
