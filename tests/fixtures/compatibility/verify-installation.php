<?php
declare(strict_types=1);
require '/var/www/html/app/bootstrap.php';
$om = Magento\Framework\App\Bootstrap::create(BP, $_SERVER)->getObjectManager();
$om->get(Magento\Framework\App\State::class)->setAreaCode('adminhtml');
$expected = $argv[1] === 'hyva' ? 'Hyva/default' : 'Magento/luma';
$design = $om->get(Magento\Framework\View\DesignInterface::class);
$factory = $om->get(Magento\Framework\View\Design\Theme\FlyweightFactory::class);
foreach ($om->get(Magento\Store\Model\StoreManagerInterface::class)->getStores() as $store) {
    if (!$store->getIsActive()) continue;
    $theme = $factory->create($design->getConfigurationDesignTheme('frontend', ['store' => $store]), 'frontend');
    if ($theme->getThemePath() !== $expected) throw new RuntimeException('Expected active ' . $expected . ', got ' . $theme->getThemePath());
}
echo 'Verified active storefront theme ', $expected, "\n";
