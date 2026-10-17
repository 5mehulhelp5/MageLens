<?php
declare(strict_types=1);
namespace MageLens\Compatibility\Block;
class Probe extends \Magento\Framework\View\Element\Template
{
    public function __construct(\Magento\Framework\View\Element\Template\Context $context, private \Magento\Framework\Data\Form\FormKey $formKey, array $data = []) { parent::__construct($context, $data); }
    public function getFormKey(): string { return $this->formKey->getFormKey(); }
}
