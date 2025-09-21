resource "aws_vpclattice_target_group" "goodbye" {
  name = "goodbye-targets"
  type = "LAMBDA"

  tags = {
    Name = "goodbye-target-group"
  }
}

resource "aws_vpclattice_target_group_attachment" "goodbye" {
  target_group_identifier = aws_vpclattice_target_group.goodbye.id

  target {
    id = aws_lambda_function.goodbye.arn
  }
}

resource "aws_lambda_permission" "lattice" {
  statement_id  = "AllowVPCLatticeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.goodbye.function_name
  principal     = "vpc-lattice.amazonaws.com"
  source_arn    = aws_vpclattice_target_group.goodbye.arn
}

