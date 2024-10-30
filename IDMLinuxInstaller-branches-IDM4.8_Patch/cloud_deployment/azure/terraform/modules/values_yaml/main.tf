
resource "local_file" "values_yaml" {
  
  content = join("\n", [
    for line in split("\n", fileexists(var.path)?file(var.path):file("${path.module}/values.yaml")):
        format(
           replace(line, "/(${join("|", keys(var.settings))}):.*/", "%s #=> Auto updated by Terraform") ,
           [
             for value in flatten(regexall("(${join("|", keys(var.settings))}):", line)) :
               format("%s: %s",value,lookup(var.settings, value))
           ]...
        )
  ])

  filename = var.path

}



