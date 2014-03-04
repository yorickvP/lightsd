// Generated by LiveScript 1.2.0
(function(){
  var http, connect, path, fs, url, moment, mu, relative, plaintext, indexTemplate, pathname, server;
  http = require('http');
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  url = require('url');
  moment = require('moment');
  mu = require('mu2');
  moment.lang('en-gb');
  relative = function(p){
    return path.resolve(__dirname, '../', p);
  };
  mu.root = relative('web');
  plaintext = curry$(function(data, res){
    res.writeHead(200, {
      'Content-Length': data.length,
      'Content-Type': "text/plain; charset=UTF-8"
    });
    return res.end(data);
  });
  indexTemplate = function(remote, res){
    return remote.lights.list(function(lights){
      var res$, i$, v;
      res$ = [];
      for (i$ in lights) {
        v = lights[i$];
        res$.push(v);
      }
      lights = res$;
      return remote.schedule.list(function(sched){
        var res$, id, v;
        res$ = [];
        for (id in sched) {
          v = sched[id];
          res$.push((v.id = id, v));
        }
        sched = res$;
        sched.forEach(function(s){
          return s.moment = moment(s.time).calendar();
        });
        lights.forEach(function(l){
          return l.sched = sched.filter(function(it){
            return it.name === l.name;
          });
        });
        res.writeHead(200, {
          'Content-Type': "text/html; charset=UTF-8"
        });
        return mu.compileAndRender('index.tmpl', {
          lights: lights,
          sched: sched
        }).pipe(res);
      });
    });
  };
  pathname = function(reqUrl){
    return url.parse(reqUrl).pathname;
  };
  module.exports = server = function(remote, port){
    var turn, okay;
    turn = remote.lights.turn;
    okay = plaintext('okay');
    return http.createServer(connect().use(connect.logger('dev')).use(connect.query()).use(function(arg$, res, next){
      var light, url;
      light = arg$.query.light, url = arg$.url;
      switch (pathname(url)) {
      case '/':
        indexTemplate(remote, res);
        break;
      case '/on':
        turn(light, true, function(){
          return okay(res);
        });
        break;
      case '/off':
        turn(light, false, function(){
          return okay(res);
        });
        break;
      default:
        next();
      }
    }).use(connect['static'](relative('web'))).use(connect.errorHandler())).listen(port);
  };
  function curry$(f, bound){
    var context,
    _curry = function(args) {
      return f.length > 1 ? function(){
        var params = args ? args.concat() : [];
        context = bound ? context || this : this;
        return params.push.apply(params, arguments) <
            f.length && arguments.length ?
          _curry.call(context, params) : f.apply(context, params);
      } : f;
    };
    return _curry();
  }
}).call(this);