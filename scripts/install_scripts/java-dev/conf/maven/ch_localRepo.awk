BEGIN{
  found="false"
  cnt=0
}
 
{
  if (found=="false" && $0 ~ /^.*<\/localRepository>/) {
    print $0;
    found="true"
    next
  }

  if (found=="true" && cnt==0) {
    print $0;
    printf "   <localRepository>";
    printf LOCAL_REPO_PATH;
    print "</localRepository>";
    cnt = -1
    next;
  }
 
  {
    print $0;
  }
}
