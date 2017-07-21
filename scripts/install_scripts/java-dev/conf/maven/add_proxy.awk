BEGIN{
}
 
{
  if ($0 ~ /^.*<\/proxies>/) {

    print "      <proxy>"
    print "        <active>true</active>"
    print "        <id>http</id>"
    print "        <protocol>http</protocol>"
    printf "        <host>"
    printf PROXY_HOST
    print "</host>"
    printf "        <port>"
    printf PROXY_PORT
    print "</port>"
    print "        <nonProxyHosts></nonProxyHosts>"
    print "      </proxy>"
    print "      <proxy>"
    print "        <active>true</active>"
    print "        <id>https</id>"
    printf "        <host>"
    printf PROXY_HOST
    print "</host>"
    printf "        <port>"
    printf PROXY_PORT
    print "</port>"
    print "        <protocol>https</protocol>"
    print "        <nonProxyHosts></nonProxyHosts>"
    print "      </proxy>"

  }
 
  {
    print $0;
  }
}
