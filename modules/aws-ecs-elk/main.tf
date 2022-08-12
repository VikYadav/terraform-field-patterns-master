/**
 * ELK Stack (ElasticSearch + FileBeat + Kibana in this case) on AWS
 */

variable "prefix" {}
variable "name" {}
variable "vpc_id" {}
variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance_role" {
  name = "${var.prefix}-ecs-instance-role"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "instance_role_policy" {
  role = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_runner" {
  name = "${var.prefix}-ecs-profile"
  path = "/"
  role = aws_iam_role.instance_role.id
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name = "${var.prefix}-ecs-runner"
  path = "/"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-attachment" {
  role = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

data "aws_ami" "ecs" {
  most_recent = true
  filter {
    name = "name"
    values = ["amzn2-ami-ecs-hvm-2.0.*"]
  }
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  owners = ["amazon"]
}

resource "aws_ecs_cluster" "this" {
  name = "${var.prefix}-${var.name}-ecs"
  tags = var.tags
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.prefix}-deployer"
  public_key = file("~/.ssh/id_rsa.pub")
  tags = var.tags
}

resource "aws_instance" "ecs_runner" {
  ami = data.aws_ami.ecs.id
  subnet_id = "subnet-01df54d04bdca058c"
  key_name = aws_key_pair.deployer.key_name

  instance_type = "i3.xlarge"
  vpc_security_group_ids = [aws_security_group.elk.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.ecs_runner.name

  user_data = <<-INIT
  echo ECS_CLUSTER=${aws_ecs_cluster.this.name} >> /etc/ecs/ecs.config
  systemctl try-restart ecs --no-block
  INIT

  tags = merge(var.tags, {
    Name = "${var.prefix}-ecs-runner"
  })
}

resource "aws_ecs_task_definition" "elk" {
  // just installation of https://elk-docker.readthedocs.io/
  family = "${var.prefix}-${var.name}-elk"
  //execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = jsonencode([
    {
      name: "${var.prefix}-${var.name}-elk",
      image: "sebp/elk",
      cpu: 1024,
      memory: 4096,
      essential: true,
      systemControls: [
        {name: "vm.max_map_count", value: "655300"}
      ],
      portMappings: [
        {containerPort: 9200}, // elasticsearch
        {containerPort: 5044}, // logstash beats
        {containerPort: 5601}, // kibana
      ],
      environment: [
        {name: "MAX_MAP_COUNT", value: "262144"}
      ],
      ulimits: [
        {
          name: "nofile",
          softLimit: 65535,
          hardLimit: 65535
        }
      ]
    }
  ])

  requires_compatibilities = ["EC2"]
  network_mode = "awsvpc"
  tags = var.tags
  cpu = 1024
  memory = 4096
}

/**
 * More focuced signle security group could be specified
 * for Single Tenant Shards by using, but it won't be necessarily
 * portable with BYOVPC scenarios, where security groups are
 * supplied on workspace creation.
 *
 * data "aws_vpc" "this" {
 *    id = var.vpc_id
 *  }
 *
 *  data "aws_security_group" "worker" {
 *    name = "${data.aws_vpc.this.tags.Name}-worker"
 *    vpc_id = var.vpc_id
 *  }
 *
 * and `data.aws_security_group.worker.id`
 */
data "aws_security_groups" "worker" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

data "http" "this_ip" {
  // retrieve this IP address for firewall opening
  url = "https://ifconfig.me"
}

resource "aws_security_group" "elk" {
  vpc_id = var.vpc_id
  name = "${var.prefix}-${var.name}-access"
  description = "Allows filebeat to forward & own IP to read"
  revoke_rules_on_delete = true

  ingress {
    from_port = 5044
    protocol = "TCP"
    to_port = 5044
    security_groups = data.aws_security_groups.worker.ids
    description = "Filebeat collector port"
  }

  ingress {
    from_port = 5601
    protocol = "TCP"
    to_port = 5601
    cidr_blocks = ["${data.http.this_ip.body}/32"]
    description = "Allow ${data.http.this_ip.body} to access Kibana"
  }

  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = ["${data.http.this_ip.body}/32"]
    description = "Allow ${data.http.this_ip.body} to SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

data "aws_subnet_ids" "worker" {
  vpc_id = var.vpc_id
}

resource "aws_ecs_service" "elk" {
  name = "${var.prefix}-${var.name}-elk"
  task_definition = aws_ecs_task_definition.elk.arn
  launch_type = "FARGATE"
  cluster = "arn:aws:ecs:eu-central-1:826763667205:cluster/default"//  aws_ecs_cluster.this.id
  desired_count = 1
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent = 100
  // tags = var.tags // The new ARN and resource ID format must be enabled to add tags to the service.
  network_configuration {
    subnets = data.aws_subnet_ids.worker.ids
    security_groups = concat(data.aws_security_groups.worker.ids, [aws_security_group.elk.id])
  }
}