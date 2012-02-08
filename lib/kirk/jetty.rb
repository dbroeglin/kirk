# Only require jars if in the "master" process
unless Kirk.sub_process?
  require "kirk/jetty/servlet-api-2.5"

  %w(util http io continuation server client webapp servlet security xml).each do |mod|
    require "kirk/jetty/jetty-#{mod}-7.4.5.v20110725"
  end
  %w(cipango-dar-2.0.0.jar cipango-deploy-2.0.0.jar cipango-main-2.0.jar cipango-server-2.0.0.jar sip-api-1.1.jar).each do |mod|
    require "kirk/jetty/#{mod}"
  end
end

module Kirk
  module Jetty
    # Gimme Jetty
    java_import "org.eclipse.jetty.client.HttpClient"
    java_import "org.eclipse.jetty.client.HttpExchange"
    java_import "org.eclipse.jetty.client.ContentExchange"

    java_import "org.eclipse.jetty.io.ByteArrayBuffer"

    java_import "org.eclipse.jetty.server.nio.SelectChannelConnector"
    java_import "org.eclipse.jetty.server.handler.AbstractHandler"
    java_import "org.eclipse.jetty.server.handler.ContextHandler"

    java_import "org.eclipse.jetty.util.component.LifeCycle"
    java_import "org.eclipse.jetty.util.log.Log"
    java_import "org.eclipse.jetty.util.log.JavaUtilLog"

    java_import "org.cipango.server.Server"
    java_import "org.cipango.server.handler.SipContextHandlerCollection"
    java_import "org.cipango.server.bio.UdpConnector"
    java_import "org.cipango.server.bio.TcpConnector"
    java_import "org.cipango.sipapp.SipAppContext"
    java_import "org.eclipse.jetty.server.bio.SocketConnector"
    java_import "org.cipango.servlet.SipServletHolder"
    java_import "javax.servlet.sip.SipServlet"

    Log.set_log Jetty::JavaUtilLog.new unless Kirk.sub_process?
  end
end
