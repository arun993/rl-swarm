import logging
import colorlog
from trl import GRPOConfig, ModelConfig, TrlParser

from hivemind_exp.chain_utils import (
    ModalSwarmCoordinator,
    WalletSwarmCoordinator,
    setup_web3,
)
from hivemind_exp.gsm8k.generate_prompts import get_stage1_samples
from hivemind_exp.runner.gensyn.testnet_grpo_runner import (
    TestnetGRPOArguments,
    TestnetGRPORunner,
)
from hivemind_exp.runner.grpo_runner import GRPOArguments, GRPORunner


def main():
    # Setup logging.
    root_logger = logging.getLogger()
    root_logger.setLevel(logging.INFO)
    handler = colorlog.StreamHandler()
    handler.setFormatter(
        colorlog.ColoredFormatter("%(green)s%(levelname)s:%(name)s:%(message)s")
    )
    root_logger.addHandler(handler)

    # Parse configurations from YAML/CLI.
    parser = TrlParser((ModelConfig, GRPOArguments, TestnetGRPOArguments, GRPOConfig))
    model_args, grpo_args, testnet_args, training_args = parser.parse_args_and_config()

    # ===== Modified Hyperparameters for Faster Training and Accuracy =====
    # Increase total training steps (allows deeper learning) and reduce logging frequency:
    training_args.max_steps = 1000           # Increased from original (e.g., 20)
    training_args.logging_steps = 10           # Log less frequently to reduce I/O overhead
    training_args.save_steps = 100             # Save checkpoints less often

    # Adjust model training parameters:
    model_args.per_device_train_batch_size = 4  # Increase batch size for better utilization
    model_args.gradient_accumulation_steps = 4    # Reduce accumulation steps to speed up updates

    # Disable gradient checkpointing when hardware allows (to avoid extra recomputation overhead)
    if hasattr(grpo_args, "gradient_checkpointing"):
        grpo_args.gradient_checkpointing = False

    # Optionally adjust learning rate and warmup (tweak these values if needed):
    if hasattr(training_args, "learning_rate"):
        training_args.learning_rate = 1.0e-6
    if hasattr(training_args, "warmup_ratio"):
        training_args.warmup_ratio = 0.05

    # If you use vLLM or other parameters that support dynamic GPU memory utilization,
    # ensure those are set appropriately in your YAML and configuration classes.

    # =======================================================================

    # Select the appropriate runner based on provided testnet arguments.
    if org_id := testnet_args.modal_org_id:
        runner = TestnetGRPORunner(ModalSwarmCoordinator(org_id, web3=setup_web3()))
    elif priv_key := testnet_args.wallet_private_key:
        runner = TestnetGRPORunner(WalletSwarmCoordinator(priv_key, web3=setup_web3()))
    else:
        runner = GRPORunner()

    # Run the main training loop with updated configurations.
    runner.run(model_args, grpo_args, training_args, get_stage1_samples)


if __name__ == "__main__":
    main()
