resource "aws_vpc" "SergeiL_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wordpress"
  }
}

resource "aws_subnet" "Sergei_public_subnet_1" {
  vpc_id                  = aws_vpc.SergeiL_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "eu-central-1a"

  tags = {
    Name = "SergeiL_public_1"
  }
}

resource "aws_subnet" "Sergei_private_subnet_1" {
  vpc_id            = aws_vpc.SergeiL_vpc.id
  cidr_block        = "10.123.2.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "SergeiL_private_1"
  }
}

resource "aws_subnet" "Sergei_public_subnet_2" {
  vpc_id            = aws_vpc.SergeiL_vpc.id
  cidr_block        = "10.123.3.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "SergeiL_public_2"
  }
}

resource "aws_subnet" "Sergei_private_subnet_2" {
  vpc_id            = aws_vpc.SergeiL_vpc.id
  cidr_block        = "10.123.4.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "SergeiL_private_2"
  }
}

resource "aws_internet_gateway" "Sergei_internet_gateway" {
  vpc_id = aws_vpc.SergeiL_vpc.id

  tags = {
    Name = "SergeiL_internet_gateway"
  }
}

resource "aws_eip" "SergeiL_elastic_ip" {
  vpc = true
}

resource "aws_nat_gateway" "SergeiL_nat_gateway" {
  allocation_id = aws_eip.SergeiL_elastic_ip.id
  subnet_id = aws_subnet.Sergei_public_subnet_1.id

  tags = {
    Name = "SergeiL_nat_gateway"
  }
}

resource "aws_route_table" "Sergei_public_rt" {
  vpc_id = aws_vpc.SergeiL_vpc.id

  route {
    cidr_block = var.CIDR_BLOCK
    gateway_id = aws_internet_gateway.Sergei_internet_gateway.id
  }

  tags = {
    Name = "Sergei_public_rt"
  }
}

resource "aws_route_table" "Sergei_private_rt" {
  vpc_id = aws_vpc.SergeiL_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Sergei_internet_gateway.id
  }

  tags = {
    Name = "Sergei_private_rt"
  }
}

resource "aws_route_table_association" "Sergei_public_subnet_1_assoc" {
  subnet_id      = aws_subnet.Sergei_public_subnet_1.id
  route_table_id = aws_route_table.Sergei_public_rt.id
  depends_on = [aws_route_table.Sergei_public_rt, aws_subnet.Sergei_public_subnet_1]
}

resource "aws_route_table_association" "Sergei_private_subnet_1_assoc" {
  subnet_id = aws_subnet.Sergei_private_subnet_1.id
  route_table_id = aws_route_table.Sergei_private_rt.id
  depends_on = [aws_route_table.Sergei_private_rt, aws_subnet.Sergei_private_subnet_1]
  
}

resource "aws_route_table_association" "Sergei_public_subnet_2_assoc" {
  subnet_id = aws_subnet.Sergei_public_subnet_2.id
  route_table_id = aws_route_table.Sergei_public_rt.id
  depends_on = [aws_route_table.Sergei_public_rt, aws_subnet.Sergei_public_subnet_2]
}

resource "aws_route_table_association" "Sergei_private_subnet_2_assoc" {
  subnet_id = aws_subnet.Sergei_private_subnet_2.id
  route_table_id = aws_route_table.Sergei_private_rt.id
  depends_on = [aws_route_table.Sergei_private_rt, aws_subnet.Sergei_private_subnet_2]
}

resource "aws_key_pair" "Sergei_auth" {
  key_name   = "Sergeikey"
  public_key = file("~/.ssh/Sergeikey.pub")
}

resource "aws_instance" "Sergei_dev_node" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.Sergei_auth.key_name
  vpc_security_group_ids = [aws_security_group.Sergei_sg.id]
  subnet_id              = aws_subnet.Sergei_public_subnet_1.id
  user_data              = file("userdata.tpl")

  root_block_device {
    volume_size = 10
  }

  tags = {
    Name = "Sergei-dev-node"
  }

  provisioner "local-exec" {
    command = templatefile("${var.host_os}-ssh-config.tpl", {
      hostname     = self.public_ip,
      user         = "ubuntu",
      identityfile = "~/.ssh/Sergeikey"
    })
    interpreter = var.host_os == "windows" ? ["Powershell", "-Command"] : ["bash", "-c"]
  }
}